import SwiftUI

struct PostMusicView: View {
    let tracks: [MusicTrack]
    @StateObject private var player = MusicPlayer.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showFullScreenPlayer = false
    
    var body: some View {
        if let track = tracks.first {
            Button(action: {
                player.setPlaylist(tracks, startIndex: 0)
                showFullScreenPlayer = true
            }) {
                HStack(spacing: 10) {
                    if let coverPath = track.cover_path, !coverPath.isEmpty, let coverURL = URL(string: coverPath) {
                        CachedAsyncImage(url: coverURL, cacheType: .post)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                            RoundedRectangle(cornerRadius: 10)
                            .fill(Color.themeBlockBackground)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.6))
                                )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let artist = track.artist {
                            Text(artist)
                                .font(.system(size: 13))
                                .foregroundColor(Color.themeTextSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: player.currentTrack?.id == track.id && player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.themeBlockBackground.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .fullScreenCover(isPresented: $showFullScreenPlayer) {
                FullScreenPlayerView()
            }
        }
    }
}

