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
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAudioSession()
        setupRemoteCommandCenter()
        setupNotifications()
    }
    
    deinit {
        // Безопасно удаляем observer при деинициализации
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
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
            print("❌ Invalid track URL")
            return
        }
        
        // Сохраняем старый player для безопасного удаления observer
        let oldPlayer = player
        
        currentTrack = track
        currentPlaylist = playlist.isEmpty ? [track] : playlist
        currentIndex = currentPlaylist.firstIndex(where: { $0.id == track.id }) ?? 0
        
        // Удаляем observer из старого player перед созданием нового
        if let observer = timeObserver, let playerToClean = oldPlayer {
            playerToClean.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        setupTimeObserver()
        updateNowPlayingInfo()
        
        player?.play()
        isPlaying = true
        
        // Отправляем событие проигрывания на сервер
        Task {
            do {
                _ = try await MusicService.shared.playTrack(trackId: track.id)
            } catch {
                print("❌ Failed to register play: \(error)")
            }
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
        player?.seek(to: cmTime)
        currentTime = time
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
    
    func stop() {
        // Удаляем observer перед остановкой player
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        player?.pause()
        player = nil
        isPlaying = false
        currentTrack = nil
        currentTime = 0
        duration = 0
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
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = TimeInterval(track.duration)
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
        // Убеждаемся, что старый observer удален (должен быть удален в playTrack)
        // Но на всякий случай проверяем еще раз
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Создаем новый observer только если player существует
        guard let currentPlayer = player else {
            return
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = currentPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
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
    }
    
    // MARK: - Notifications
    @objc private func playerDidFinishPlaying() {
        nextTrack()
    }
    
    @objc private func playerItemFailedToPlay() {
        print("❌ Player item failed to play")
        stop()
    }
    
    // MARK: - Playlist Management
    private var currentPlaylist: [MusicTrack] = []
    private var currentIndex: Int = 0
    
    func setPlaylist(_ tracks: [MusicTrack], startIndex: Int = 0) {
        currentPlaylist = tracks
        currentIndex = min(startIndex, tracks.count - 1)
        if !tracks.isEmpty {
            playTrack(tracks[currentIndex], playlist: tracks)
        }
    }
}

