import SwiftUI

enum ImageCacheType {
    case post
    case avatar
    case banner
    case musicCover
}

struct CachedAsyncImage: View {
    let url: URL?
    let cacheType: ImageCacheType
    @StateObject private var themeManager = ThemeManager.shared
    @State private var loadedImage: UIImage?
    @State private var isLoading: Bool = false
    
    init(url: URL?, cacheType: ImageCacheType) {
        self.url = url
        self.cacheType = cacheType
        // Проверяем кеш синхронно при инициализации для мгновенного отображения
        if let imageURL = url {
            var cachedData: Data?
            switch cacheType {
            case .post:
                cachedData = CacheManager.shared.getCachedPostImage(url: imageURL)
            case .avatar:
                cachedData = CacheManager.shared.getCachedAvatar(url: imageURL)
            case .banner:
                cachedData = CacheManager.shared.getCachedBanner(url: imageURL)
            case .musicCover:
                cachedData = CacheManager.shared.getCachedMusicCover(url: imageURL)
            }
            
            if let data = cachedData, let image = UIImage(data: data) {
                _loadedImage = State(initialValue: image)
            }
        }
    }
    
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
        .task(priority: .background) {
            await loadImageFromNetwork()
        }
        .onChange(of: url) { oldValue, newValue in
            if newValue != oldValue {
                loadedImage = nil
                isLoading = false
                // Проверяем кеш для нового URL
                if let imageURL = newValue {
                    var cachedData: Data?
                    switch cacheType {
                    case .post:
                        cachedData = CacheManager.shared.getCachedPostImage(url: imageURL)
                    case .avatar:
                        cachedData = CacheManager.shared.getCachedAvatar(url: imageURL)
                    case .banner:
                        cachedData = CacheManager.shared.getCachedBanner(url: imageURL)
                    case .musicCover:
                        cachedData = CacheManager.shared.getCachedMusicCover(url: imageURL)
                    }
                    
                    if let data = cachedData, let image = UIImage(data: data) {
                        loadedImage = image
                        return
                    }
                }
                Task(priority: .background) {
                    await loadImageFromNetwork()
                }
            }
        }
    }
    
    private func loadImageFromNetwork() async {
        guard let url = url else {
            return
        }
        
        // Если уже загружено из кеша, не загружаем снова
        if loadedImage != nil {
            return
        }
        
        isLoading = true
        
        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = urlResponse as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
            }
            
            if let image = UIImage(data: data) {
                // Сохраняем в кеш в фоне
                Task.detached(priority: .background) {
                    switch cacheType {
                    case .post:
                        await CacheManager.shared.cachePostImage(url: url, data: data)
                    case .avatar:
                        await CacheManager.shared.cacheAvatar(url: url, data: data)
                    case .banner:
                        await CacheManager.shared.cacheBanner(url: url, data: data)
                    case .musicCover:
                        await CacheManager.shared.cacheMusicCover(url: url, data: data)
                    }
                }
                
                await MainActor.run {
                    loadedImage = image
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

