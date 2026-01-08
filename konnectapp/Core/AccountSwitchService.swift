import Foundation
import UIKit

class AccountSwitchService {
    static let shared = AccountSwitchService()
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
    
    func getMyChannels() async throws -> MyChannelsResponse {
        guard let url = URL(string: "\(baseURL)/api/users/my-channels") else {
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
        
        if httpResponse.statusCode == 401 {
            try? KeychainManager.deleteTokens()
            throw AuthError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let errorMessage = errorResponse.error ?? errorResponse.message ?? "Ошибка сервера"
                return MyChannelsResponse(success: false, current_account: nil, main_account: nil, channels: [], error: errorMessage)
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MyChannelsResponse.self, from: data)
    }
    
    func switchAccount(accountId: Int64) async throws -> SwitchAccountResponse {
        guard let url = URL(string: "\(baseURL)/api/users/switch-account") else {
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
        
        let body = SwitchAccountRequest(account_id: accountId)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("🟡 AccountSwitchService: Switching to account \(accountId)")
        print("🔵 SWITCH ACCOUNT REQUEST:")
        print("URL: \(url.absoluteString)")
        print("Method: POST")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        print("🟢 SWITCH ACCOUNT RESPONSE:")
        print("Status Code: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Body: \(responseString.prefix(500))")
        }
        
        if httpResponse.statusCode == 401 {
            try? KeychainManager.deleteTokens()
            throw AuthError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let errorMessage = errorResponse.error ?? errorResponse.message ?? "Ошибка сервера"
                print("❌ AccountSwitchService: Switch failed: \(errorMessage)")
                return SwitchAccountResponse(success: false, account: nil, error: errorMessage)
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let switchResponse = try decoder.decode(SwitchAccountResponse.self, from: data)
        
        if switchResponse.success {
            // КРИТИЧЕСКАЯ ПРОВЕРКА: убеждаемся, что API вернул тот же ID, который был запрошен
            if let returnedAccount = switchResponse.account, returnedAccount.id != accountId {
                let errorMessage = "API вернул другой аккаунт (запрошен: \(accountId), получен: \(returnedAccount.id))"
                print("❌ AccountSwitchService: \(errorMessage)")
                print("⚠️ Это критическая ошибка - API не выполнил переключение корректно")
                // Возвращаем ошибку вместо успешного ответа
                return SwitchAccountResponse(success: false, account: nil, error: errorMessage)
            }
            print("🟢 AccountSwitchService: Successfully switched to account: \(switchResponse.account?.username ?? "nil") (ID: \(switchResponse.account?.id ?? -1))")
        } else {
            print("❌ AccountSwitchService: Switch failed: \(switchResponse.error ?? "unknown error")")
        }
        
        return switchResponse
    }
}
