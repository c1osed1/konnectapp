import Foundation
import UIKit

class ProfileService {
    static let shared = ProfileService()
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
    
    func getProfile(userIdentifier: String) async throws -> ProfileResponse {
        guard let url = URL(string: "\(baseURL)/api/profile/\(userIdentifier)") else {
            throw AuthError.invalidResponse
        }
        
        var request = URLRequest(url: url)
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
        
        print("🔵 PROFILE REQUEST:")
        print("URL: \(url.absoluteString)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AuthError.invalidResponse
        }
        
        print("🟢 PROFILE RESPONSE:")
        print("Status Code: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response body (first 1000 chars): \(String(responseString.prefix(1000)))")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            if httpResponse.statusCode == 404 {
                throw AuthError.invalidResponse
            }
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let profileResponse = try decoder.decode(ProfileResponse.self, from: data)
            print("✅ Decoded Profile Response:")
            print("User: \(profileResponse.user.name)")
            return profileResponse
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error:")
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context)")
            case .keyNotFound(let key, let context):
                print("Key '\(key.stringValue)' not found: \(context)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type \(type): \(context)")
            case .valueNotFound(let type, let context):
                print("Value not found for type \(type): \(context)")
            @unknown default:
                print("Unknown decoding error: \(decodingError)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            throw decodingError
        } catch {
            print("❌ Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            throw error
        }
    }
    
    func getProfilePosts(userIdentifier: String, page: Int = 1, perPage: Int = 10, mediaFilter: String? = nil) async throws -> FeedResponse {
        guard let url = URL(string: "\(baseURL)/api/profile/\(userIdentifier)/posts") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        if let mediaFilter = mediaFilter {
            queryItems.append(URLQueryItem(name: "media_filter", value: mediaFilter))
        }
        
        components.queryItems = queryItems
        
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
        
        print("🔵 PROFILE POSTS REQUEST:")
        print("URL: \(finalURL.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(FeedResponse.self, from: data)
    }
    
    func followUser(followedId: Int64) async throws -> FollowResponse {
        guard let url = URL(string: "\(baseURL)/api/profile/follow") else {
            throw AuthError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        let body = ["followed_id": followedId]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("🔵 FOLLOW REQUEST:")
        print("URL: \(url.absoluteString)")
        print("Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        return try JSONDecoder().decode(FollowResponse.self, from: data)
    }
    
    func getProfileWall(userIdentifier: String, page: Int = 1, perPage: Int = 10) async throws -> FeedResponse {
        guard let url = URL(string: "\(baseURL)/api/profile/\(userIdentifier)/wall") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
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
        
        print("🔵 PROFILE WALL REQUEST:")
        print("URL: \(finalURL.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(FeedResponse.self, from: data)
    }
    
    func getPinnedPost(userIdentifier: String) async throws -> PinnedPostResponse? {
        guard let url = URL(string: "\(baseURL)/api/profile/pinned_post/\(userIdentifier)") else {
            throw AuthError.invalidResponse
        }
        
        var request = URLRequest(url: url)
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
        
        print("🔵 PINNED POST REQUEST:")
        print("URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        print("🟢 PINNED POST RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        // Если поста нет, возвращаем nil (404 или пустой ответ)
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // Важно: не используем convertFromSnakeCase, потому что модели (Post, etc.)
        // уже описаны в snake_case (например, is_pinned) и имеют свои CodingKeys.
        
        do {
            let response = try decoder.decode(PinnedPostResponse.self, from: data)
            return response.success == true ? response : nil
        } catch {
            print("⚠️ Failed to decode pinned post: \(error)")
            return nil
        }
    }
}

struct FollowResponse: Codable {
    let success: Bool
    let is_following: Bool
    let message: String?
}

struct PinnedPostResponse: Codable {
    let success: Bool?
    let post: Post?
}

