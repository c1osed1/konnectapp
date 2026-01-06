import SwiftUI
import Combine

struct ProfileBanner: View {
    let bannerURL: String?
    let height: CGFloat
    
    var body: some View {
        Group {
            if let bannerURL = bannerURL, let url = URL(string: bannerURL) {
                CachedAsyncImage(url: url, cacheType: .banner)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.themeBackgroundStart,
                                Color.themeBlockBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: height)
            }
        }
    }
}

