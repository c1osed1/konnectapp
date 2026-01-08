import Foundation
import UIKit

class AuthService {
    static let shared = AuthService()
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
    
    func login(username: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        let body = LoginRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("🔵 LOGIN REQUEST:")
        print("URL: \(url.absoluteString)")
        print("Method: POST")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw AuthError.invalidResponse
            }
            
            print("🟢 LOGIN RESPONSE:")
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            print("Data size: \(data.count) bytes")
            
            if data.isEmpty {
                print("❌ Empty response data")
                throw AuthError.invalidResponse
            }
            
            guard let responseString = String(data: data, encoding: .utf8) else {
                print("❌ Cannot convert response to string")
                throw AuthError.invalidResponse
            }
            
            print("Body: \(responseString)")
            
            if httpResponse.statusCode == 403 {
                print("⚠️ Access forbidden (403)")
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let errorMessage = errorResponse.message ?? errorResponse.error ?? "Доступ запрещен"
                    print("Error message: \(errorMessage)")
                    return LoginResponse(
                        success: false,
                        user: nil,
                        sessionKey: nil,
                        session_key: nil,
                        token: nil,
                        error: errorMessage,
                        ban_info: nil,
                        message: errorMessage
                    )
                }
                throw AuthError.banned
            }
            
            let loginResponse: LoginResponse
            do {
                let decoder = JSONDecoder()
                loginResponse = try decoder.decode(LoginResponse.self, from: data)
            } catch let decodingError as DecodingError {
                print("❌ JSON Decoding Error:")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context)")
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context)")
                    if key.stringValue == "success" {
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            let errorMessage = errorResponse.message ?? errorResponse.error ?? "Ошибка сервера"
                            return LoginResponse(
                                success: false,
                                user: nil,
                                sessionKey: nil,
                                session_key: nil,
                                token: nil,
                                error: errorMessage,
                                ban_info: nil,
                                message: errorMessage
                            )
                        }
                    }
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type): \(context)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type): \(context)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
                throw AuthError.invalidResponse
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                throw AuthError.invalidResponse
            }
            
            print("✅ Decoded Response:")
            print("Success: \(loginResponse.success ?? false)")
            print("Error: \(loginResponse.error ?? loginResponse.message ?? "nil")")
            print("Token: \(loginResponse.token != nil ? "present" : "nil")")
            print("SessionKey: \(loginResponse.session_key != nil ? "present" : "nil")")
            
            if loginResponse.success == true, let token = loginResponse.token, let sessionKey = loginResponse.session_key {
                try KeychainManager.save(token: token, sessionKey: sessionKey)
                if let user = loginResponse.user {
                    UserDefaults.standard.set(user.id, forKey: "currentUserId")
                }
                print("✅ Tokens saved successfully")
            } else {
                let errorMsg = loginResponse.error ?? loginResponse.message ?? "Неизвестная ошибка"
                print("⚠️ Login failed: success=\(loginResponse.success ?? false), error=\(errorMsg)")
            }
            
            return loginResponse
        } catch {
            print("❌ LOGIN ERROR: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("Decoding error: \(decodingError)")
            }
            throw error
        }
    }
    
    func checkAuth() async throws -> CheckAuthResponse {
        guard let token = try? KeychainManager.getToken() else {
            return CheckAuthResponse(
                isAuthenticated: false,
                user: nil,
                sessionExists: false,
                needsProfileSetup: nil,
                user_id: nil,
                hasAuthMethod: nil,
                chat_id: nil,
                error: "No token found",
                ban_info: nil,
                message: nil
            )
        }
        
        let url = URL(string: "\(baseURL)/api/auth/check")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            try? KeychainManager.deleteTokens()
            throw AuthError.unauthorized
        }
        
        if httpResponse.statusCode == 403 {
            try? KeychainManager.deleteTokens()
            throw AuthError.banned
        }
        
        // Логируем ответ для отладки
        if let responseString = String(data: data, encoding: .utf8) {
            print("🟡 AuthService checkAuth response (first 1000 chars):")
            print(responseString.prefix(1000))
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        do {
            let authResponse = try decoder.decode(CheckAuthResponse.self, from: data)
            
            if let user = authResponse.user {
                print("🟢 AuthService: Decoded user successfully")
                print("   - Username: \(user.username)")
                print("   - profile_background_url: \(user.profile_background_url ?? "nil")")
                print("   - avatar_url: \(user.avatar_url ?? "nil")")
            } else {
                print("⚠️ AuthService: User is nil in response")
            }
            
            return authResponse
        } catch let decodingError as DecodingError {
            print("❌ AuthService: Decoding error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Key '\(key.stringValue)' not found: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type): \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found for \(type): \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   Unknown error: \(decodingError)")
            }
            throw decodingError
        } catch {
            print("❌ AuthService: Unexpected error: \(error)")
            throw error
        }
    }
    
    func logout() async throws {
        guard let token = try? KeychainManager.getToken() else {
            try? KeychainManager.deleteTokens()
            return
        }
        
        let url = URL(string: "\(baseURL)/api/auth/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode([String: String]())
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        try KeychainManager.deleteTokens()
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.logoutFailed
        }
    }
}
