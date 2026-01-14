import Foundation
import UIKit

class PostActionService {
    static let shared = PostActionService()
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
        return "KConnect-iOS/1.2.6 (iPhone; iOS \(systemVersion); Scale/\(scale))"
    }
    
    private init() {}
    
    func pinPost(postId: Int64) async throws -> Bool {
        guard let token = try KeychainManager.getToken() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/pin_post/\(postId)") else {
            throw PostActionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 PIN POST REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostActionError.invalidResponse
        }
        
        print("🟢 PIN POST RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw PostActionError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw PostActionError.serverError(httpResponse.statusCode)
        }
        
        return true
    }
    
    func unpinPost() async throws -> Bool {
        guard let token = try KeychainManager.getToken() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/unpin_post") else {
            throw PostActionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 UNPIN POST REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostActionError.invalidResponse
        }
        
        print("🟢 UNPIN POST RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw PostActionError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw PostActionError.serverError(httpResponse.statusCode)
        }
        
        return true
    }
    
    func deletePost(postId: Int64) async throws -> Bool {
        guard let token = try KeychainManager.getToken() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/posts/\(postId)") else {
            throw PostActionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 DELETE POST REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostActionError.invalidResponse
        }
        
        print("🟢 DELETE POST RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw PostActionError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw PostActionError.serverError(httpResponse.statusCode)
        }
        
        return true
    }
    
    func repostPost(postId: Int64, text: String? = nil) async throws -> RepostResponse {
        guard let token = try KeychainManager.getToken() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/posts/\(postId)/repost") else {
            throw PostActionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let body: [String: Any] = ["text": text ?? ""]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔵 REPOST REQUEST: URL: \(url.absoluteString) Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostActionError.invalidResponse
        }
        
        print("🟢 REPOST RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw PostActionError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw PostActionError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(RepostResponse.self, from: data)
    }

    func editPost(
        postId: Int64,
        content: String,
        deleteImages: Bool = false,
        deleteVideo: Bool = false,
        deleteMusic: Bool = false
    ) async throws -> Post {
        guard let token = try KeychainManager.getToken() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/posts/\(postId)/edit") else {
            throw PostActionError.invalidURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        func appendFormField(_ name: String, _ value: String, to data: inout Data) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        var body = Data()
        appendFormField("content", content, to: &body)
        appendFormField("delete_images", deleteImages ? "true" : "false", to: &body)
        appendFormField("delete_video", deleteVideo ? "true" : "false", to: &body)
        appendFormField("delete_music", deleteMusic ? "true" : "false", to: &body)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("🔵 EDIT POST REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostActionError.invalidResponse
        }
        
        print("🟢 EDIT POST RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw PostActionError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw PostActionError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EditPostResponse.self, from: data)
        if decoded.success == true, let updatedPost = decoded.post {
            return updatedPost
        }
        throw PostActionError.invalidResponse
    }
    
    func reportPost(postId: Int64, reason: String, description: String?) async throws -> ReportResponse {
        guard let token = try KeychainManager.getToken() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PostActionError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/report/send-to-telegram") else {
            throw PostActionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        var body: [String: Any] = [
            "post_id": postId,
            "reason": reason
        ]
        
        if let description = description, !description.isEmpty {
            body["description"] = description
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔵 REPORT REQUEST: URL: \(url.absoluteString) Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostActionError.invalidResponse
        }
        
        print("🟢 REPORT RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw PostActionError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw PostActionError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ReportResponse.self, from: data)
    }
}

struct RepostResponse: Codable {
    let success: Bool?
    let message: String?
    let repost_id: Int64?
}

struct ReportResponse: Codable {
    let success: Bool?
    let message: String?
    let report_id: Int64?
}

enum PostActionError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
}

