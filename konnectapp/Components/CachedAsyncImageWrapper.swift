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
    @State private var isLoading: Bool = false
    
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
                loadedImage = nil
                isLoading = false
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            print("⚠️ CachedAsyncImage: URL is nil")
            return
        }
        
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
            print("✅ CachedAsyncImage: Using cached image for \(url.absoluteString)")
            loadedImage = image
            isLoading = false
            return
        }
        
        isLoading = true
        print("📥 CachedAsyncImage: Fetching image from network: \(url.absoluteString)")
        Task {
            do {
                var request = URLRequest(url: url)
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
                let (data, urlResponse) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = urlResponse as? HTTPURLResponse {
                    print("📥 CachedAsyncImage: Response status code: \(httpResponse.statusCode) for \(url.absoluteString)")
                    if httpResponse.statusCode != 200 {
                        print("⚠️ CachedAsyncImage: Non-200 status code for \(url.absoluteString)")
                    }
                }
                
                if let image = UIImage(data: data) {
                    print("✅ CachedAsyncImage: Successfully loaded image from \(url.absoluteString)")
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
                        isLoading = false
                    }
                } else {
                    print("❌ CachedAsyncImage: Failed to create UIImage from data for \(url.absoluteString)")
                    await MainActor.run {
                        isLoading = false
                    }
                }
            } catch {
                print("❌ CachedAsyncImage: Error loading image from \(url.absoluteString): \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

