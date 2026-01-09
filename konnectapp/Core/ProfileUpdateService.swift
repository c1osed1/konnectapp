import Foundation
import UIKit

class ProfileUpdateService {
    static let shared = ProfileUpdateService()
    private let baseURL = "https://k-connect.ru"
    
    private var userAgent: String {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let scale = window.screen.scale
            return "KConnect-iOS/1.2.4 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/\(String(format: "%.1f", scale)))"
        }
        return "KConnect-iOS/1.2.4 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/3.0)"
    }
    
    private init() {}
    
    func updateName(_ name: String) async throws -> Bool {
        guard let token = try KeychainManager.getToken() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/update-name") else {
            throw ProfileUpdateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileUpdateError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return true
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw ProfileUpdateError.serverError(httpResponse.statusCode)
        }
    }
    
    func updateUsername(_ username: String) async throws -> Bool {
        guard let token = try KeychainManager.getToken() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/update-username") else {
            throw ProfileUpdateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": username]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileUpdateError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return true
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw ProfileUpdateError.serverError(httpResponse.statusCode)
        }
    }
    
    func uploadAvatar(_ image: UIImage) async throws -> String {
        guard let token = try KeychainManager.getToken() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/upload-avatar") else {
            throw ProfileUpdateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ProfileUpdateError.invalidImage
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileUpdateError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
            return uploadResponse.avatar_url ?? ""
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw ProfileUpdateError.serverError(httpResponse.statusCode)
        }
    }
    
    func uploadBanner(_ image: UIImage) async throws -> String {
        guard let token = try KeychainManager.getToken() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/upload-banner") else {
            throw ProfileUpdateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ProfileUpdateError.invalidImage
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"banner\"; filename=\"banner.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileUpdateError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
            return uploadResponse.banner_url ?? ""
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw ProfileUpdateError.serverError(httpResponse.statusCode)
        }
    }
    
    func updateProfileStyle(_ profileId: Int) async throws -> Bool {
        guard let token = try KeychainManager.getToken() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/user/profile-style") else {
            throw ProfileUpdateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["profile_id": profileId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileUpdateError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return true
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw ProfileUpdateError.serverError(httpResponse.statusCode)
        }
    }
    
    func uploadBackground(_ image: UIImage) async throws -> String {
        guard let token = try KeychainManager.getToken() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/background") else {
            throw ProfileUpdateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ProfileUpdateError.invalidImage
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"background\"; filename=\"background.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileUpdateError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let uploadResponse = try decoder.decode(BackgroundUploadResponse.self, from: data)
            return uploadResponse.profile_background_url ?? ""
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Background upload error response: \(jsonString)")
            }
            if httpResponse.statusCode == 403 {
                throw ProfileUpdateError.noSubscription
            }
            throw ProfileUpdateError.serverError(httpResponse.statusCode)
        }
    }
    
    func deleteBackground() async throws -> Bool {
        guard let token = try KeychainManager.getToken() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/profile/background") else {
            throw ProfileUpdateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileUpdateError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return true
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Background delete error response: \(jsonString)")
            }
            if httpResponse.statusCode == 403 {
                throw ProfileUpdateError.noSubscription
            }
            throw ProfileUpdateError.serverError(httpResponse.statusCode)
        }
    }
}

struct UploadResponse: Codable {
    let success: Bool
    let message: String?
    let avatar_url: String?
    let banner_url: String?
    let error: String?
}

struct BackgroundUploadResponse: Codable {
    let success: Bool
    let message: String?
    let profile_background_url: String?
    let error: String?
}

enum ProfileUpdateError: Error {
    case noSubscription
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case invalidImage
    
    var localizedDescription: String {
        switch self {
        case .noSubscription:
            return "Фоновая картинка доступна только для Ultimate, MAX и Pick-Me"
        case .notAuthenticated:
            return "Не авторизован"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .invalidImage:
            return "Неверное изображение"
        }
    }
}

