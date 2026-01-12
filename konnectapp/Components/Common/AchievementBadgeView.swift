import SwiftUI
import WebKit

struct AchievementBadgeView: View {
    let imagePath: String
    let size: CGFloat
    
    init(imagePath: String, size: CGFloat = 16) {
        self.imagePath = imagePath
        self.size = size
    }
    
    var body: some View {
        Group {
            if imagePath.lowercased().hasSuffix(".svg") {
                SVGBadgeView(url: imagePath, size: size)
            } else if imagePath.lowercased().hasSuffix(".gif") {
                // Пропускаем GIF - не отображаем
                EmptyView()
            } else {
                // Для всех остальных форматов (WEBP, PNG, JPG и т.д.) используем UIImage
                CachedBadgeImageView(url: imagePath, size: size)
            }
        }
    }
}

// MARK: - SVG Badge View
struct SVGBadgeView: View {
    let url: String
    let size: CGFloat
    @State private var svgContent: String?
    @State private var hasError: Bool = false
    
    init(url: String, size: CGFloat) {
        self.url = url
        self.size = size
        // Проверяем кеш синхронно при инициализации для мгновенного отображения
        if let badgeURL = URL(string: url),
           let cachedData = CacheManager.shared.getCachedBadge(url: badgeURL),
           let cachedString = String(data: cachedData, encoding: .utf8) {
            let cleanedSVG = cachedString.replacingOccurrences(of: ".webp", with: "", options: .caseInsensitive)
            _svgContent = State(initialValue: cleanedSVG)
        }
    }
    
    var body: some View {
        Group {
            if hasError {
                // Если ошибка - не показываем ничего
                EmptyView()
            } else if let svgContent = svgContent {
                SVGView(svgString: svgContent)
                    .frame(width: size, height: size)
            } else {
                // Не показываем ProgressView, чтобы не блокировать UI
                // Просто пустое место, бейдж загрузится в фоне
                Color.clear
                    .frame(width: size, height: size)
                    .task(priority: .background) {
                        await loadSVGFromNetwork()
                    }
            }
        }
    }
    
    private func loadSVGFromNetwork() async {
        guard let badgeURL = URL(string: url) else {
            await MainActor.run {
                self.hasError = true
            }
            return
        }
        
        // Загружаем из сети с таймаутом в фоновом потоке
        var request = URLRequest(url: badgeURL)
        request.timeoutInterval = 5.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                await MainActor.run {
                    self.hasError = true
                }
                return
            }
            
            if let svgString = String(data: data, encoding: .utf8) {
                // Очищаем SVG от потенциальных внешних ресурсов WEBP
                let cleanedSVG = svgString.replacingOccurrences(of: ".webp", with: "", options: .caseInsensitive)
                
                // Сохраняем в кеш оригинальные данные в фоне
                Task.detached(priority: .background) {
                    CacheManager.shared.cacheBadge(url: badgeURL, data: data)
                }
                
                await MainActor.run {
                    self.svgContent = cleanedSVG
                }
            } else {
                await MainActor.run {
                    self.hasError = true
                }
            }
        } catch {
            await MainActor.run {
                self.hasError = true
            }
        }
    }
}

// MARK: - Cached Badge Image View
struct CachedBadgeImageView: View {
    let url: String
    let size: CGFloat
    @State private var cachedImage: UIImage?
    @State private var hasError: Bool = false
    
    init(url: String, size: CGFloat) {
        self.url = url
        self.size = size
        // Проверяем кеш синхронно при инициализации для мгновенного отображения
        if let imageURL = URL(string: url),
           let cachedData = CacheManager.shared.getCachedBadge(url: imageURL),
           let image = UIImage(data: cachedData) {
            _cachedImage = State(initialValue: image)
        }
    }
    
    var body: some View {
        Group {
            if hasError {
                // Если ошибка - не показываем ничего
                EmptyView()
            } else if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                // Не показываем ProgressView, чтобы не блокировать UI
                // Просто пустое место, бейдж загрузится в фоне
                Color.clear
                    .frame(width: size, height: size)
                    .task(priority: .background) {
                        await loadImageFromNetwork()
                    }
            }
        }
    }
    
    private func loadImageFromNetwork() async {
        guard let imageURL = URL(string: url) else {
            await MainActor.run {
                self.hasError = true
            }
            return
        }
        
        // Загружаем из сети с таймаутом в фоновом потоке
        var request = URLRequest(url: imageURL)
        request.timeoutInterval = 5.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                await MainActor.run {
                    self.hasError = true
                }
                return
            }
            
            if let image = UIImage(data: data) {
                // Сохраняем в кеш в фоне
                Task.detached(priority: .background) {
                    CacheManager.shared.cacheBadge(url: imageURL, data: data)
                }
                
                await MainActor.run {
                    self.cachedImage = image
                }
            } else {
                await MainActor.run {
                    self.hasError = true
                }
            }
        } catch {
            await MainActor.run {
                self.hasError = true
            }
        }
    }
}
