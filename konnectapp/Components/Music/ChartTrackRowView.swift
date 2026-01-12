import SwiftUI

struct ChartTrackRowView: View {
    let track: MusicTrack
    let position: Int
    let onPlay: () -> Void
    let onLike: () -> Void
    @StateObject private var player = MusicPlayer.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Позиция в чарте
                Text("\(position)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(position <= 3 ? Color.appAccent : Color.themeTextSecondary)
                    .frame(width: 30)
                
                // Обложка
                Group {
                    if let coverPath = track.cover_path, !coverPath.isEmpty, let coverURL = URL(string: coverPath) {
                        CachedAsyncImage(url: coverURL, cacheType: .musicCover)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
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
                            .frame(width: 60, height: 60)
                    }
                }
                
                // Информация о треке
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(track.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                            .lineLimit(1)
                        
                        // Тренд стрелка
                        if let trend = track.trend {
                            Image(systemName: trendIcon(trend))
                                .font(.system(size: 12))
                                .foregroundColor(trendColor(trend))
                        }
                    }
                    
                    Text(track.artist ?? track.user_name ?? "Unknown Artist")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        if let playsCount = track.plays_count {
                            Label("\(formatCount(playsCount))", systemImage: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.themeTextSecondary)
                        }
                        
                        if let likesCount = track.likes_count {
                            Label("\(formatCount(likesCount))", systemImage: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.themeTextSecondary)
                        }
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
                        .foregroundColor(track.is_liked == true ? Color.red : Color.themeTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func trendIcon(_ trend: String) -> String {
        switch trend {
        case "up": return "arrow.up"
        case "down": return "arrow.down"
        case "stable": return "minus"
        default: return "minus"
        }
    }
    
    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "up": return .green
        case "down": return .red
        case "stable": return Color.themeTextSecondary
        default: return Color.themeTextSecondary
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }
}

