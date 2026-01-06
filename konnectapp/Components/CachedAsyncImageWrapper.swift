import SwiftUI

enum ImageCacheType {
    case post
    case avatar
    case banner
}

struct CachedAsyncImage: View {
    let url: URL?
    let cacheType: ImageCacheType
    @StateObject private var themeManager = ThemeManager.shared
    @State private var loadedImage: UIImage?
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
            } else {
                Rectangle()
                    .fill(Color.themeBlockBackground)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { oldValue, newValue in
            if newValue != oldValue {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        var cachedData: Data?
        switch cacheType {
        case .post:
            cachedData = CacheManager.shared.getCachedPostImage(url: url)
        case .avatar:
            cachedData = CacheManager.shared.getCachedAvatar(url: url)
        case .banner:
            cachedData = CacheManager.shared.getCachedBanner(url: url)
        }
        
        if let data = cachedData, let image = UIImage(data: data) {
            loadedImage = image
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    switch cacheType {
                    case .post:
                        CacheManager.shared.cachePostImage(url: url, data: data)
                    case .avatar:
                        CacheManager.shared.cacheAvatar(url: url, data: data)
                    case .banner:
                        CacheManager.shared.cacheBanner(url: url, data: data)
                    }
                    await MainActor.run {
                        loadedImage = image
                    }
                }
            } catch {
                print("❌ Error loading image: \(error)")
            }
        }
    }
}

