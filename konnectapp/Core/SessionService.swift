//
//  SessionService.swift
//  konnectapp
//
//  Service for managing user sessions
//

import Foundation
import UIKit

class SessionService {
    static let shared = SessionService()
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
    
    private func makeRequest(url: URL, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        if method == "POST" || method == "DELETE" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let body = body {
                request.httpBody = body
            } else if method == "DELETE" {
                // Для DELETE запроса отправляем пустой JSON объект
                request.httpBody = "{}".data(using: .utf8)
            }
        }
        
        return request
    }
    
    // MARK: - Get Sessions
    
    func getSessions() async throws -> [Session] {
        guard let url = URL(string: "\(baseURL)/api/auth/sessions") else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: url)
        
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
        let sessionsResponse = try decoder.decode(SessionsResponse.self, from: data)
        return sessionsResponse.sessions
    }
    
    // MARK: - Delete Session
    
    func deleteSession(sessionId: Int64) async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/sessions/\(sessionId)") else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: url, method: "DELETE")
        
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
        
        // Проверяем ответ
        if let deleteResponse = try? JSONDecoder().decode(DeleteSessionResponse.self, from: data) {
            if !deleteResponse.success {
                throw AuthError.invalidResponse
            }
        }
    }
}
