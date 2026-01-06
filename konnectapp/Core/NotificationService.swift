import Foundation
import UIKit

class NotificationService {
    static let shared = NotificationService()
    private let baseURL = "https://k-connect.ru"
    
    private var userAgent: String {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let scale = window.screen.scale
            return "KConnect-iOS/1.0 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/\(String(format: "%.1f", scale)))"
        }
        return "KConnect-iOS/1.0 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/3.0)"
    }
    
    private init() {}
    
    func getNotifications() async throws -> NotificationsResponse {
        guard let token = try KeychainManager.getToken() else {
            throw NotificationError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw NotificationError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/notifications/") else {
            throw NotificationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                let notificationsResponse = try decoder.decode(NotificationsResponse.self, from: data)
                return notificationsResponse
            } catch {
                print("❌ Notification decoding error: \(error)")
                throw NotificationError.decodingError(error)
            }
        } else {
            throw NotificationError.serverError(httpResponse.statusCode)
        }
    }
    
    func markAllAsRead() async throws -> MarkAllReadResponse {
        guard let token = try KeychainManager.getToken() else {
            throw NotificationError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw NotificationError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/notifications/mark-all-read") else {
            throw NotificationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let markReadResponse = try decoder.decode(MarkAllReadResponse.self, from: data)
                return markReadResponse
            } catch {
                print("❌ Mark all read decoding error: \(error)")
                throw NotificationError.decodingError(error)
            }
        } else {
            throw NotificationError.serverError(httpResponse.statusCode)
        }
    }
    
    func deleteAllNotifications() async throws -> DeleteAllResponse {
        guard let token = try KeychainManager.getToken() else {
            throw NotificationError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw NotificationError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/notifications/") else {
            throw NotificationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let deleteResponse = try decoder.decode(DeleteAllResponse.self, from: data)
                return deleteResponse
            } catch {
                print("❌ Delete all notifications decoding error: \(error)")
                throw NotificationError.decodingError(error)
            }
        } else {
            throw NotificationError.serverError(httpResponse.statusCode)
        }
    }
}

struct MarkAllReadResponse: Codable {
    let success: Bool
    let message: String?
    let count: Int?
    let unread_count: Int?
}

struct DeleteAllResponse: Codable {
    let success: Bool
    let message: String?
    let count: Int?
}

enum NotificationError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "Не авторизован"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        }
    }
}

