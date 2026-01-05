import SwiftUI

struct PostMusicView: View {
    let tracks: [MusicTrack]
    @State private var isPlaying: Bool = false
    @State private var currentTrackIndex: Int = 0
    
    var body: some View {
        if let track = tracks.first {
            Button(action: {
                // TODO: Implement music playback
                isPlaying.toggle()
            }) {
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.6))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.6))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let artist = track.artist {
                            Text(artist)
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
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
        }
    }
}

