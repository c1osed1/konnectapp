import Foundation
import UIKit

class OnlineUsersService {
    static let shared = OnlineUsersService()
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
        return "KConnect-iOS/1.2.3 (iPhone; iOS \(systemVersion); Scale/\(scale))"
    }
    
    private init() {}
    
    func getOnlineUsers(limit: Int? = nil) async throws -> [PostUser] {
        var urlString = "\(baseURL)/api/users/online"
        if let limit = limit {
            urlString += "?limit=\(limit)"
        }
        
        guard let url = URL(string: urlString) else {
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
        
        print("🔵 ONLINE USERS REQUEST:")
        print("URL: \(urlString)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AuthError.invalidResponse
        }
        
        print("🟢 ONLINE USERS RESPONSE:")
        print("Status Code: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Body: \(responseString.prefix(500))")
        }
        
        if let users = try? JSONDecoder().decode([PostUser].self, from: data) {
            print("✅ Decoded \(users.count) online users")
            return users
        }
        
        struct OnlineUsersResponse: Codable {
            let users: [PostUser]?
        }
        
        let responseObj = try JSONDecoder().decode(OnlineUsersResponse.self, from: data)
        let users = responseObj.users ?? []
        print("✅ Decoded \(users.count) online users from object")
        return users
    }
}

