import Foundation
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Music Player
// Для работы фонового воспроизведения необходимо:
// 1. В Xcode: Target -> Signing & Capabilities -> Background Modes -> включить "Audio, AirPlay, and Picture in Picture"
// 2. В Info.plist добавить: UIBackgroundModes = ["audio"]

class MusicPlayer: ObservableObject {
    static let shared = MusicPlayer()
    
    @Published var currentTrack: MusicTrack?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var observerPlayer: AVPlayer? // Player, к которому был добавлен observer
    private var statusObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    private var currentPlaylist: [MusicTrack] = []
    private var currentIndex: Int = 0
    private var isPlayingTrack = false // Флаг для предотвращения одновременных вызовов
    private var retryCount: [Int64: Int] = [:] // Счетчик попыток для каждого трека
    
    private init() {
        setupAudioSession()
        setupRemoteCommandCenter()
        setupNotifications()
    }
    
    deinit {
        // Безопасно удаляем observer при деинициализации
        cleanupTimeObserver()
        statusObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func cleanupTimeObserver() {
        if let observer = timeObserver, let playerToClean = observerPlayer {
            playerToClean.removeTimeObserver(observer)
            timeObserver = nil
            observerPlayer = nil
        }
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Сначала деактивируем сессию, если она активна
            if audioSession.isOtherAudioPlaying {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            }
            // Устанавливаем категорию
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .mixWithOthers])
            // Активируем сессию
            try audioSession.setActive(true, options: [])
        } catch {
            // Ошибка -50 (kAudioSessionInvalidPropertyError) может возникать если сессия уже настроена
            // Это не критично, просто логируем
            if (error as NSError).code != -50 {
            print("❌ Failed to setup audio session: \(error)")
            }
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if self?.isPlaying == true {
                self?.pause()
            } else {
                self?.play()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: nil
        )
    }
    
    // MARK: - Playback Control
    func playTrack(_ track: MusicTrack, playlist: [MusicTrack] = []) {
        guard let filePath = track.file_path, let url = URL(string: filePath) else {
            print("❌ [MusicPlayer] Invalid track URL for track ID: \(track.id)")
            return
        }
        
        // Предотвращаем одновременные вызовы
        guard !isPlayingTrack else {
            print("⚠️ [MusicPlayer] playTrack already in progress, skipping track ID: \(track.id)")
            return
        }
        
        isPlayingTrack = true
        
        print("🎵 [MusicPlayer] Starting to play track ID: \(track.id), title: \(track.title)")
        
        // Синхронно очищаем старый observer на MainActor
        Task { @MainActor in
            cleanupTimeObserver()
            
            // Останавливаем старый player
            player?.pause()
            player = nil
            
            currentTrack = track
            currentPlaylist = playlist.isEmpty ? [track] : playlist
            currentIndex = currentPlaylist.firstIndex(where: { $0.id == track.id }) ?? 0
            
            let playURL: URL
            let useOriginalURL = retryCount[track.id] ?? 0 > 0 // Используем оригинальный URL после первой ошибки
            
            if useOriginalURL {
                // После ошибки используем оригинальный URL напрямую
                playURL = url
                print("🌐 [MusicPlayer] Using original URL (retry attempt) for ID: \(track.id)")
            } else if let cachedURL = CacheManager.shared.getCachedTrack(url: url) {
                playURL = cachedURL
                print("✅ [MusicPlayer] Using cached track for ID: \(track.id)")
            } else {
                print("📥 [MusicPlayer] Downloading track for ID: \(track.id)")
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    
                    // Проверяем Content-Type
                    if let httpResponse = response as? HTTPURLResponse,
                       let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                        print("📋 [MusicPlayer] Content-Type: \(contentType)")
                        
                        // Проверяем, что это аудио файл
                        if !contentType.contains("audio") && !contentType.contains("mpeg") && !contentType.contains("mp3") {
                            print("⚠️ [MusicPlayer] Suspicious Content-Type, but proceeding...")
                        }
                    }
                    
                    // Проверяем размер данных
                    print("📊 [MusicPlayer] Downloaded data size: \(data.count) bytes")
                    if data.count < 1024 {
                        print("❌ [MusicPlayer] Downloaded file is too small (\(data.count) bytes), using original URL")
                        playURL = url
                    } else {
                        CacheManager.shared.cacheTrack(url: url, data: data)
                        if let cachedURL = CacheManager.shared.getCachedTrack(url: url) {
                            playURL = cachedURL
                            print("✅ [MusicPlayer] Track cached successfully for ID: \(track.id)")
                        } else {
                            playURL = url
                            print("⚠️ [MusicPlayer] Failed to get cached URL, using original for ID: \(track.id)")
                        }
                    }
                } catch {
                    print("❌ [MusicPlayer] Error caching track ID \(track.id): \(error.localizedDescription)")
                    playURL = url
                }
            }
            
            // Удаляем старый status observer
            statusObserver?.invalidate()
            statusObserver = nil
            
            let newPlayerItem = AVPlayerItem(url: playURL)
            self.playerItem = newPlayerItem
            
            print("📦 [MusicPlayer] PlayerItem created, URL: \(playURL.path)")
            print("📊 [MusicPlayer] PlayerItem initial status: \(newPlayerItem.status.rawValue)")
            
            // Проверяем ошибку сразу
            if let error = newPlayerItem.error {
                print("❌ [MusicPlayer] PlayerItem has error: \(error.localizedDescription)")
                isPlayingTrack = false
                return
            }
            
            player = AVPlayer(playerItem: newPlayerItem)
            observerPlayer = player // Сохраняем ссылку на player для observer
            
            print("✅ [MusicPlayer] Player created for track ID: \(track.id)")
            print("🔊 [MusicPlayer] Audio session category: \(AVAudioSession.sharedInstance().category.rawValue)")
            print("🔊 [MusicPlayer] Audio session is active: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
            
            // Наблюдаем за статусом playerItem
            statusObserver = newPlayerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.handlePlayerItemStatusChange(item: item, trackId: track.id)
                }
            }
            
            // Настраиваем observer только после создания player
            setupTimeObserver()
            
            // Обновляем Now Playing Info
            updateNowPlayingInfo()
            
            // Если playerItem уже готов, запускаем воспроизведение
            if newPlayerItem.status == .readyToPlay {
                print("✅ [MusicPlayer] PlayerItem is ready, starting playback")
                startPlayback()
            } else {
                print("⏳ [MusicPlayer] PlayerItem status: \(newPlayerItem.status.rawValue), waiting for ready state...")
            }
            
            // Регистрируем проигрывание в API
            Task {
                do {
                    _ = try await MusicService.shared.playTrack(trackId: track.id)
                    print("✅ [MusicPlayer] Play registered in API for track ID: \(track.id)")
                } catch {
                    print("❌ [MusicPlayer] Failed to register play for track ID \(track.id): \(error.localizedDescription)")
                }
            }
            
            isPlayingTrack = false
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime) { [weak self] completed in
            if completed {
                self?.currentTime = time
                self?.updateNowPlayingInfo()
            }
        }
    }
    
    func nextTrack() {
        guard !currentPlaylist.isEmpty else { return }
        currentIndex = (currentIndex + 1) % currentPlaylist.count
        playTrack(currentPlaylist[currentIndex], playlist: currentPlaylist)
    }
    
    func previousTrack() {
        guard !currentPlaylist.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : currentPlaylist.count - 1
        playTrack(currentPlaylist[currentIndex], playlist: currentPlaylist)
    }
    
    func setPlaylist(_ tracks: [MusicTrack], startIndex: Int = 0) {
        guard !tracks.isEmpty, startIndex >= 0, startIndex < tracks.count else { return }
        currentPlaylist = tracks
        currentIndex = startIndex
        playTrack(tracks[startIndex], playlist: tracks)
    }
    
    func stop() {
        print("⏹️ [MusicPlayer] Stopping playback")
        // Удаляем observer перед остановкой player
        cleanupTimeObserver()
        statusObserver?.invalidate()
        statusObserver = nil
        
        player?.pause()
        player = nil
        playerItem = nil
        observerPlayer = nil
        isPlaying = false
        currentTrack = nil
        currentTime = 0
        duration = 0
        isPlayingTrack = false
        retryCount.removeAll()
    }
    
    private func handlePlayerItemStatusChange(item: AVPlayerItem, trackId: Int64) {
        print("📊 [MusicPlayer] PlayerItem status changed to: \(item.status.rawValue) for track ID: \(trackId)")
        
        switch item.status {
        case .readyToPlay:
            print("✅ [MusicPlayer] PlayerItem is ready to play for track ID: \(trackId)")
            if let error = item.error {
                print("⚠️ [MusicPlayer] PlayerItem has error despite ready status: \(error.localizedDescription)")
            }
            startPlayback()
        case .failed:
            if let error = item.error {
                print("❌ [MusicPlayer] PlayerItem failed for track ID \(trackId): \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("❌ [MusicPlayer] Error domain: \(nsError.domain), code: \(nsError.code)")
                    print("❌ [MusicPlayer] Error userInfo: \(nsError.userInfo)")
                    
                    // Если ошибка "Cannot Open" (-11828), возможно поврежден кеш или неподдерживаемый формат
                    if nsError.domain == "AVFoundationErrorDomain" && nsError.code == -11828 {
                        let currentRetryCount = retryCount[trackId] ?? 0
                        
                        if currentRetryCount == 0 {
                            // Первая попытка: удаляем кеш и пробуем снова
                            print("🔄 [MusicPlayer] Cannot Open error detected, removing cached file and retrying...")
                            if let currentTrack = currentTrack,
                               let filePath = currentTrack.file_path,
                               let url = URL(string: filePath) {
                                CacheManager.shared.removeCachedTrack(url: url)
                                retryCount[trackId] = 1
                                
                                // Перезагружаем трек
                                Task { @MainActor in
                                    print("🔄 [MusicPlayer] Retrying track ID: \(trackId) after cache removal")
                                    isPlayingTrack = false
                                    playTrack(currentTrack, playlist: currentPlaylist)
                                }
                                return
                            }
                        } else if currentRetryCount == 1 {
                            // Вторая попытка: используем оригинальный URL
                            print("🔄 [MusicPlayer] Cannot Open error persists, trying original URL...")
                            if let currentTrack = currentTrack {
                                retryCount[trackId] = 2
                                
                                // Перезагружаем трек с оригинальным URL
                                Task { @MainActor in
                                    print("🔄 [MusicPlayer] Retrying track ID: \(trackId) with original URL")
                                    isPlayingTrack = false
                                    playTrack(currentTrack, playlist: currentPlaylist)
                                }
                                return
                            }
                        } else {
                            // Третья попытка и далее: формат не поддерживается
                            print("❌ [MusicPlayer] Track format is not supported after multiple attempts for track ID: \(trackId)")
                            retryCount.removeValue(forKey: trackId)
                            isPlayingTrack = false
                            
                            // Показываем ошибку пользователю
                            print("❌ [MusicPlayer] Cannot play track ID \(trackId): Media format not supported")
                            return
                        }
                    }
                }
            } else {
                print("❌ [MusicPlayer] PlayerItem failed for track ID \(trackId): unknown error")
            }
            isPlayingTrack = false
        case .unknown:
            print("⏳ [MusicPlayer] PlayerItem status unknown for track ID: \(trackId)")
        @unknown default:
            print("⚠️ [MusicPlayer] PlayerItem unknown status: \(item.status.rawValue) for track ID: \(trackId)")
        }
    }
    
    private func startPlayback() {
        guard let currentPlayer = player else {
            print("⚠️ [MusicPlayer] Cannot start playback: player is nil")
            return
        }
        
        guard currentPlayer.status == .readyToPlay || currentPlayer.currentItem?.status == .readyToPlay else {
            print("⚠️ [MusicPlayer] Cannot start playback: player/item not ready, status: \(currentPlayer.status.rawValue)")
            return
        }
        
        print("▶️ [MusicPlayer] Starting playback...")
        currentPlayer.play()
        isPlaying = true
        
        // Сбрасываем счетчик попыток при успешном старте
        if let trackId = currentTrack?.id {
            retryCount.removeValue(forKey: trackId)
        }
        
        // Проверяем через небольшую задержку, действительно ли началось воспроизведение
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if let rate = self.player?.rate, rate > 0 {
                print("✅ [MusicPlayer] Playback started successfully, rate: \(rate)")
            } else {
                print("❌ [MusicPlayer] Playback failed to start, player rate: \(self.player?.rate ?? 0)")
                if let error = self.player?.error {
                    print("❌ [MusicPlayer] Player error: \(error.localizedDescription)")
                }
                if let itemError = self.player?.currentItem?.error {
                    print("❌ [MusicPlayer] PlayerItem error: \(itemError.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }
        
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist ?? track.user_name ?? "Unknown Artist"
        
        if let album = track.album {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }
        
        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        } else {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = TimeInterval(track.duration)
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        
        // Загружаем обложку
        if let coverPath = track.cover_path, let coverURL = URL(string: coverPath) {
            Task {
                if let image = await loadImage(from: coverURL) {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("❌ Failed to load cover image: \(error)")
            return nil
        }
    }
    
    // MARK: - Time Observer
    private func setupTimeObserver() {
        // Убеждаемся, что старый observer удален
        cleanupTimeObserver()
        
        // Создаем новый observer только если player существует
        guard let currentPlayer = player else {
            print("⚠️ [MusicPlayer] Cannot setup time observer: player is nil")
            return
        }
        
        // Убеждаемся, что observer добавляется к правильному player
        observerPlayer = currentPlayer
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = currentPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            // Проверяем, что observer все еще относится к текущему player
            guard self.player === self.observerPlayer else {
                print("⚠️ [MusicPlayer] Time observer called for wrong player, cleaning up")
                return
            }
            
            self.currentTime = time.seconds
            
            if let duration = self.player?.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
            
            // Обновляем Now Playing Info
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? self.playbackRate : 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
        
        print("✅ [MusicPlayer] Time observer setup successfully")
    }
    
    // MARK: - Notifications
    @objc private func playerDidFinishPlaying() {
        nextTrack()
    }
    
    @objc private func playerItemFailedToPlay() {
        print("❌ Player item failed to play")
        stop()
    }
}

