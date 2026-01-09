import Foundation
import UIKit

class LikeService {
    static let shared = LikeService()
    
    private init() {}
    
    private var userAgent: String {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let scale = window.screen.scale
            return "KConnect-iOS/1.2.4 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/\(String(format: "%.1f", scale)))"
        }
        return "KConnect-iOS/1.2.4 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/3.0)"
    }
    
    func toggleLike(postId: Int) async throws -> PostLikeResponse {
        guard let token = try KeychainManager.getToken() else {
            throw LikeError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw LikeError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/posts/\(postId)/like") else {
            throw LikeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🟢 LIKE REQUEST: URL: \(url.absoluteString) Method: POST Headers: [\"Authorization\": \"Bearer \(token.prefix(20))...\", \"User-Agent\": \"\(userAgent)\", \"X-Mobile-Client\": \"true\", \"X-Session-Key\": \"\(sessionKey.prefix(20))...\"]")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LikeError.invalidResponse
        }
        
        print("🟢 LIKE RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let likeResponse = try decoder.decode(PostLikeResponse.self, from: data)
                print("🟢 LIKE SUCCESS: liked=\(likeResponse.liked), likes_count=\(likeResponse.likesCount)")
                return likeResponse
            } catch {
                print("❌ JSON Decoding Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response body: \(jsonString)")
                }
                throw LikeError.decodingError(error)
            }
        } else {
            print("❌ LIKE ERROR: Status Code: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw LikeError.serverError(httpResponse.statusCode)
        }
    }
}

struct PostLikeResponse: Codable {
    let liked: Bool
    let likesCount: Int
    let success: Bool
}

enum LikeError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "Не авторизован"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        }
    }
}

