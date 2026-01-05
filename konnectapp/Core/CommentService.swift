import Foundation
import UIKit

class CommentService {
    static let shared = CommentService()
    
    private init() {}
    
    private var userAgent: String {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let scale = window.screen.scale
            return "KConnect-iOS/1.0 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/\(String(format: "%.1f", scale)))"
        }
        return "KConnect-iOS/1.0 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/3.0)"
    }
    
    func getPostDetail(postId: Int64, includeComments: Bool = false) async throws -> PostDetailResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        var urlString = "https://k-connect.ru/api/posts/\(postId)"
        if includeComments {
            urlString += "?include_comments=true"
        }
        
        guard let url = URL(string: urlString) else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 POST DETAIL REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 POST DETAIL RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PostDetailResponse.self, from: data)
    }
    
    func getComments(postId: Int64, page: Int = 1, limit: Int = 20) async throws -> CommentsResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/posts/\(postId)/comments?page=\(page)&limit=\(limit)") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 COMMENTS REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 COMMENTS RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CommentsResponse.self, from: data)
    }
    
    func createComment(postId: Int64, content: String?, image: UIImage?) async throws -> CreateCommentResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/posts/\(postId)/comments") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if let content = content, !content.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
            body.append(content.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("🔵 CREATE COMMENT REQUEST: URL: \(url.absoluteString) Content length: \(body.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 CREATE COMMENT RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if httpResponse.statusCode == 429 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Rate limit error: \(errorString)")
                }
                throw CommentError.rateLimit
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CreateCommentResponse.self, from: data)
    }
    
    func likeComment(commentId: Int64) async throws -> LikeResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/comments/\(commentId)/like") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 LIKE COMMENT REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 LIKE COMMENT RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(LikeResponse.self, from: data)
    }
}

enum CommentError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case rateLimit
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "Не авторизован"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .unauthorized:
            return "Сессия истекла"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .rateLimit:
            return "Слишком много запросов. Подождите немного."
        }
    }
}

