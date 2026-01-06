import SwiftUI

struct ProfileAvatar: View {
    let avatarURL: String?
    let size: CGFloat
    let borderColor: Color
    let isOnline: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let avatarURL = avatarURL, let url = URL(string: avatarURL) {
                    CachedAsyncImage(url: url, cacheType: .avatar)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.2, blue: 0.3),
                                    Color(red: 0.15, green: 0.15, blue: 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                }
            }
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: 4)
            )
            
            if isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.05, green: 0.05, blue: 0.05), lineWidth: 2)
                    )
                    .offset(x: -2, y: -2)
            }
        }
        .frame(width: size, height: size)
    }
}

