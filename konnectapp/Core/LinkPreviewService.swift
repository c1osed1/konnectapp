import Foundation
import UIKit

class LinkPreviewService {
    static let shared = LinkPreviewService()
    private let baseURL = "https://k-connect.ru"
    
    private var userAgent: String {
        let systemVersion = UIDevice.current.systemVersion
        let scale: CGFloat
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            scale = window.screen.scale
        } else {
            scale = 3.0
        }
        return "KConnect-iOS/1.2.5 (iPhone; iOS \(systemVersion); Scale/\(scale))"
    }
    
    private init() {}
    
    func getLinkPreview(url: String) async throws -> LinkPreviewData? {
        guard let requestURL = URL(string: "\(baseURL)/api/utils/link-preview") else {
            throw AuthError.invalidResponse
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        // Токен не обязателен для этого API, но если есть - используем
        if let token = try? KeychainManager.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        let body = LinkPreviewRequest(url: url)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw AuthError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let previewResponse = try decoder.decode(LinkPreviewResponse.self, from: data)
        
        if previewResponse.success, let internalData = previewResponse.data {
            // Создаем LinkPreviewData с URL
            return LinkPreviewData(
                title: internalData.title,
                description: internalData.description,
                image: internalData.image,
                source: internalData.source,
                url: url
            )
        }
        
        return nil
    }
}

struct LinkPreviewRequest: Codable {
    let url: String
}

struct LinkPreviewResponse: Codable {
    let success: Bool
    fileprivate let data: LinkPreviewDataInternal?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success, data, message
    }
}

// Внутренняя структура для декодирования (без URL)
fileprivate struct LinkPreviewDataInternal: Codable {
    let title: String
    let description: String?
    let image: String?
    let source: String?
}

struct LinkPreviewData: Identifiable, Hashable {
    var id: String { url }
    let title: String
    let description: String?
    let image: String?
    let source: String?
    let url: String
    
    init(title: String, description: String?, image: String?, source: String?, url: String) {
        self.title = title
        self.description = description
        self.image = image
        self.source = source
        self.url = url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: LinkPreviewData, rhs: LinkPreviewData) -> Bool {
        lhs.url == rhs.url
    }
}
