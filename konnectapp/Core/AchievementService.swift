import Foundation
import UIKit

class AchievementService {
    static let shared = AchievementService()
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
        return "KConnect-iOS/1.2.4 (iPhone; iOS \(systemVersion); Scale/\(scale))"
    }
    
    private init() {}
    
    func getAchievements() async throws -> AchievementsResponse {
        guard let url = URL(string: "\(baseURL)/api/profile/achievements") else {
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
        
        do {
            return try decoder.decode(AchievementsResponse.self, from: data)
        } catch {
            print("❌ AchievementService: Error decoding achievements: \(error)")
            throw error
        }
    }
    
    func activateAchievement(achievementId: Int64) async throws -> ActivateAchievementResponse {
        guard let url = URL(string: "\(baseURL)/api/profile/achievements/active") else {
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
        
        let requestBody = ActivateAchievementRequest(achievement_id: achievementId)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
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
        
        do {
            return try decoder.decode(ActivateAchievementResponse.self, from: data)
        } catch {
            print("❌ AchievementService: Error decoding activate response: \(error)")
            throw error
        }
    }
    
    func deactivateAchievement() async throws -> DeactivateAchievementResponse {
        guard let url = URL(string: "\(baseURL)/api/profile/achievements/deactivate") else {
            throw AuthError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
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
        
        do {
            return try decoder.decode(DeactivateAchievementResponse.self, from: data)
        } catch {
            print("❌ AchievementService: Error decoding deactivate response: \(error)")
            throw error
        }
    }
}
