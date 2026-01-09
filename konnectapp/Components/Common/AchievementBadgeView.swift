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
    
    var body: some View {
        Group {
            if hasError {
                // Если ошибка - не показываем ничего
                EmptyView()
            } else if let svgContent = svgContent {
                SVGView(svgString: svgContent)
                    .frame(width: size, height: size)
            } else {
                ProgressView()
                    .frame(width: size, height: size)
                    .onAppear {
                        loadSVG()
                    }
            }
        }
    }
    
    private func loadSVG() {
        guard let url = URL(string: url) else {
            DispatchQueue.main.async {
                self.hasError = true
            }
            return
        }
        
        // Проверяем кеш
        if let cachedData = CacheManager.shared.getCachedBadge(url: url),
           let cachedString = String(data: cachedData, encoding: .utf8) {
            // Очищаем SVG от потенциальных внешних ресурсов WEBP
            let cleanedSVG = cachedString.replacingOccurrences(of: ".webp", with: "", options: .caseInsensitive)
            DispatchQueue.main.async {
                self.svgContent = cleanedSVG
            }
            return
        }
        
        // Загружаем из сети с таймаутом
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ SVG Badge load error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.hasError = true
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ SVG Badge HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                DispatchQueue.main.async {
                    self.hasError = true
                }
                return
            }
            
            if let data = data, let svgString = String(data: data, encoding: .utf8) {
                // Очищаем SVG от потенциальных внешних ресурсов WEBP
                let cleanedSVG = svgString.replacingOccurrences(of: ".webp", with: "", options: .caseInsensitive)
                
                // Сохраняем в кеш оригинальные данные
                CacheManager.shared.cacheBadge(url: url, data: data)
                
                DispatchQueue.main.async {
                    self.svgContent = cleanedSVG
                }
            } else {
                DispatchQueue.main.async {
                    self.hasError = true
                }
            }
        }.resume()
    }
}

// MARK: - Cached Badge Image View
struct CachedBadgeImageView: View {
    let url: String
    let size: CGFloat
    @State private var cachedImage: UIImage?
    @State private var hasError: Bool = false
    
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
                ProgressView()
                    .frame(width: size, height: size)
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let imageURL = URL(string: url) else {
            DispatchQueue.main.async {
                self.hasError = true
            }
            return
        }
        
        // Проверяем кеш
        if let cachedData = CacheManager.shared.getCachedBadge(url: imageURL),
           let image = UIImage(data: cachedData) {
            DispatchQueue.main.async {
                self.cachedImage = image
            }
            return
        }
        
        // Загружаем из сети с таймаутом
        var request = URLRequest(url: imageURL)
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Badge Image load error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.hasError = true
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ Badge Image HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                DispatchQueue.main.async {
                    self.hasError = true
                }
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                // Сохраняем в кеш
                CacheManager.shared.cacheBadge(url: imageURL, data: data)
                
                DispatchQueue.main.async {
                    self.cachedImage = image
                }
            } else {
                DispatchQueue.main.async {
                    self.hasError = true
                }
            }
        }.resume()
    }
}
