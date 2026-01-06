import SwiftUI

struct TrackRowView: View {
    let track: MusicTrack
    let onPlay: () -> Void
    let onLike: () -> Void
    @StateObject private var player = MusicPlayer.shared
    
    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Обложка
                AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appAccent.opacity(0.3),
                                        Color.appAccent.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.appAccent)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appAccent.opacity(0.3),
                                        Color.appAccent.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.appAccent)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Информация о треке
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artist ?? track.user_name ?? "Unknown Artist")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                        .lineLimit(1)
                    
                    if let genre = track.genre {
                        Text(genre)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Индикатор воспроизведения
                if player.currentTrack?.id == track.id && player.isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appAccent)
                        .symbolEffect(.pulse)
                }
                
                // Кнопка лайка
                Button(action: onLike) {
                    Image(systemName: track.is_liked == true ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(track.is_liked == true ? Color.red : Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

