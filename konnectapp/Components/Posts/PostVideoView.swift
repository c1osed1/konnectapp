import SwiftUI
import AVKit

struct PostVideoView: View {
    let videoURL: String
    let posterURL: String?
    let isNsfw: Bool
    @State private var showNsfw: Bool = false
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var hasLoadedPlayer: Bool = false
    @State private var showFullscreenPlayer: Bool = false
    
    var body: some View {
        ZStack(alignment: .center) {
            if showNsfw || !isNsfw {
                if URL(string: videoURL) != nil {
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(contentMode: .fit)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(maxHeight: 450)
                            .clipped()
                            .onTapGesture(count: 2) {
                                // Двойной тап открывает полноэкранный режим
                                showFullscreenPlayer = true
                            }
                            .onDisappear {
                                player.pause()
                                isPlaying = false
                            }
                    } else {
                        // Показываем постер пока загружается видео
                        if let posterURL = posterURL, let posterImageURL = URL(string: posterURL) {
                            CachedAsyncImage(url: posterImageURL, cacheType: .post)
                                .aspectRatio(contentMode: .fit)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(maxHeight: 450)
                                .overlay(
                                    Button(action: {
                                        playVideo()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.7))
                                                .frame(width: 64, height: 64)
                                            Image(systemName: "play.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 28, weight: .medium))
                                                .offset(x: 2)
                                        }
                                    }
                                )
                                .clipped()
                                .onTapGesture(count: 2) {
                                    showFullscreenPlayer = true
                                }
                        } else {
                            // Плейсхолдер если нет постера
                            ZStack {
                                Rectangle()
                                    .fill(Color.themeBlockBackground)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 450)
                                
                                Button(action: {
                                    playVideo()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.7))
                                            .frame(width: 64, height: 64)
                                        Image(systemName: "play.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 28, weight: .medium))
                                            .offset(x: 2)
                                    }
                                }
                            }
                            .onTapGesture(count: 2) {
                                showFullscreenPlayer = true
                            }
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.themeBlockBackground)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 450)
                }
            } else {
                // NSFW blur
                if let posterURL = posterURL, let posterImageURL = URL(string: posterURL) {
                    CachedAsyncImage(url: posterImageURL, cacheType: .post)
                        .aspectRatio(contentMode: .fit)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(maxHeight: 450)
                        .blur(radius: 20)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.themeBlockBackground)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 450)
                }
                
                Button(action: {
                    showNsfw = true
                }) {
                    VStack {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        Text("NSFW")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                    )
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipped()
        .fullScreenCover(isPresented: $showFullscreenPlayer) {
            FullScreenVideoPlayerView(videoURL: videoURL, posterURL: posterURL, existingPlayer: player) { newPlayer in
                // Обновляем player после создания полноэкранного
                if let newPlayer = newPlayer {
                    self.player = newPlayer
                    self.hasLoadedPlayer = true
                }
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL), !hasLoadedPlayer else { return }
        
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        hasLoadedPlayer = true
        
        // Не запускаем автоматически, ждем нажатия play
    }
    
    private func playVideo() {
        guard let player = player else {
            setupPlayer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.player?.play()
                self.isPlaying = true
            }
            return
        }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
}

// MARK: - Full Screen Video Player

struct FullScreenVideoPlayerView: View {
    let videoURL: String
    let posterURL: String?
    let existingPlayer: AVPlayer?
    let onPlayerCreated: (AVPlayer?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var fullscreenPlayer: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = fullscreenPlayer {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else if URL(string: videoURL) != nil {
                // Показываем постер или placeholder пока загружается
                ZStack {
                    if let posterURL = posterURL, let posterImageURL = URL(string: posterURL) {
                        CachedAsyncImage(url: posterImageURL, cacheType: .post)
                            .aspectRatio(contentMode: .fit)
                            .ignoresSafeArea()
                    } else {
                        Rectangle()
                            .fill(Color.black)
                            .ignoresSafeArea()
                    }
                    
                    ProgressView()
                        .tint(.white)
                }
            }
            
            // Кнопка закрытия
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                            )
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .onAppear {
            setupFullscreenPlayer()
        }
    }
    
    private func setupFullscreenPlayer() {
        // Используем существующий player или создаем новый
        if let existingPlayer = existingPlayer {
            fullscreenPlayer = existingPlayer
        } else if let url = URL(string: videoURL) {
            let newPlayer = AVPlayer(url: url)
            fullscreenPlayer = newPlayer
            onPlayerCreated(newPlayer)
        }
    }
}
