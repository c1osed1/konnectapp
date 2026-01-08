import Foundation
import UIKit

class SearchService {
    static let shared = SearchService()
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
        return "KConnect-iOS/1.2.2 (iPhone; iOS \(systemVersion); Scale/\(scale))"
    }
    
    private init() {}
    
    private func makeRequest(url: URL, method: String = "GET") throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "accept")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        return request
    }
    
    // MARK: - Search Users
    func searchUsers(query: String, perPage: Int = 5) async throws -> UsersSearchResponse {
        guard let url = URL(string: "\(baseURL)/api/search/") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "users"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let finalURL = components.url else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: finalURL)
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
        return try decoder.decode(UsersSearchResponse.self, from: data)
    }
    
    // MARK: - Search Channels
    func searchChannels(query: String, perPage: Int = 5) async throws -> ChannelsSearchResponse {
        guard let url = URL(string: "\(baseURL)/api/search/channels") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let finalURL = components.url else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: finalURL)
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
        return try decoder.decode(ChannelsSearchResponse.self, from: data)
    }
}

