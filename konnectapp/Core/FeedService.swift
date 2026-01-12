import Foundation
import UIKit

class FeedService {
    static let shared = FeedService()
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
    
    func getFeed(
        page: Int = 1,
        perPage: Int = 20,
        sort: FeedType = .all,
        includeAll: Bool = false
    ) async throws -> FeedResponse {
        guard let url = URL(string: "\(baseURL)/api/posts/feed") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "sort", value: sort.rawValue),
            URLQueryItem(name: "include_all", value: includeAll ? "true" : "false")
        ]
        
        guard let finalURL = components.url else {
            throw AuthError.invalidResponse
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        print("🔵 FEED REQUEST:")
        print("URL: \(finalURL.absoluteString)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AuthError.invalidResponse
        }
        
        print("🟢 FEED RESPONSE:")
        print("Status Code: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Body: \(responseString.prefix(500))")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let feedResponse = try decoder.decode(FeedResponse.self, from: data)
            print("✅ Decoded Feed Response:")
            print("Posts count: \(feedResponse.posts.count)")
            print("Has next: \(feedResponse.has_next)")
            return feedResponse
        } catch {
            print("❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type): \(context)")
                default:
                    print("Decoding error: \(decodingError)")
                }
            }
            throw error
        }
    }
}

