//
//  MessengerService.swift
//  konnectapp
//
//  REST API service for messenger functionality
//

import Foundation
import UIKit

class MessengerService {
    static let shared = MessengerService()
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
    
    private func makeRequest(url: URL, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw MessengerError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        if method == "POST" || method == "PUT" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - Chats
    
    func getChats() async throws -> [Chat] {
        guard let url = URL(string: "\(baseURL)/api/messenger/chats") else {
            throw MessengerError.invalidURL
        }
        
        let request = try makeRequest(url: url)
        
        print("🔵 GET CHATS REQUEST:")
        print("URL: \(url.absoluteString)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw MessengerError.invalidResponse
        }
        
        print("🟢 GET CHATS RESPONSE:")
        print("Status Code: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response body: \(errorString)")
            }
            throw MessengerError.invalidResponse
        }
        
        do {
            // Try to decode as ChatsResponse first
            if let chatsResponse = try? JSONDecoder().decode(ChatsResponse.self, from: data) {
                print("✅ Decoded \(chatsResponse.chats.count) chats from REST API (wrapped)")
                return chatsResponse.chats
            }
            
            // Try to decode as direct array
            if let chatsArray = try? JSONDecoder().decode([Chat].self, from: data) {
                print("✅ Decoded \(chatsArray.count) chats from REST API (array)")
                return chatsArray
            }
            
            // If both fail, try to decode as object with chats array
            let chatsResponse = try JSONDecoder().decode(ChatsResponse.self, from: data)
            print("✅ Decoded \(chatsResponse.chats.count) chats from REST API")
            return chatsResponse.chats
        } catch {
            print("❌ Error decoding chats: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
            }
            throw error
        }
    }
    
    func getChat(chatId: Int64) async throws -> Chat {
        guard let url = URL(string: "\(baseURL)/api/messenger/chats/\(chatId)") else {
            throw MessengerError.invalidURL
        }
        
        let request = try makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.invalidResponse
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.chat
    }
    
    // MARK: - Messages
    
    func getMessages(chatId: Int64, limit: Int? = 50, beforeId: Int64? = nil, forceRefresh: Bool = false) async throws -> [Message] {
        var urlString = "\(baseURL)/api/messenger/chats/\(chatId)/messages"
        var queryItems: [URLQueryItem] = []
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        if let beforeId = beforeId {
            queryItems.append(URLQueryItem(name: "before_id", value: "\(beforeId)"))
        }
        if forceRefresh {
            queryItems.append(URLQueryItem(name: "force_refresh", value: "true"))
        }
        
        if !queryItems.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = queryItems
            urlString = components?.url?.absoluteString ?? urlString
        }
        
        guard let url = URL(string: urlString) else {
            throw MessengerError.invalidURL
        }
        
        let request = try makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response body: \(errorString)")
            }
            throw MessengerError.invalidResponse
        }
        
        do {
            let messagesResponse = try JSONDecoder().decode(MessagesResponse.self, from: data)
            return messagesResponse.messages
        } catch {
            // Try to decode as direct array if wrapped response fails
            if let messagesArray = try? JSONDecoder().decode([Message].self, from: data) {
                print("✅ Decoded \(messagesArray.count) messages from REST API (direct array)")
                return messagesArray
            }
            print("❌ Error decoding messages: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
            }
            throw error
        }
    }
    
    func sendMessage(chatId: Int64, text: String, replyToId: Int64? = nil) async throws -> Message {
        guard let url = URL(string: "\(baseURL)/api/messenger/chats/\(chatId)/messages") else {
            throw MessengerError.invalidURL
        }
        
        let body: [String: Any] = [
            "text": text,
            "reply_to_id": replyToId as Any
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = try makeRequest(url: url, method: "POST", body: bodyData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.messageSendFailed
        }
        
        let sendResponse = try JSONDecoder().decode(SendMessageResponse.self, from: data)
        return sendResponse.message
    }
    
    // MARK: - File Upload
    
    func uploadFile(chatId: Int64, fileData: Data, fileName: String, mimeType: String, messageType: String, replyToId: Int64? = nil) async throws -> Message {
        guard let url = URL(string: "\(baseURL)/api/messenger/chats/\(chatId)/upload") else {
            throw MessengerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw MessengerError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add message_type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"message_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(messageType)\r\n".data(using: .utf8)!)
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add reply_to_id if present
        if let replyToId = replyToId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"reply_to_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(replyToId)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.fileUploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadFileResponse.self, from: data)
        return uploadResponse.message
    }
    
    func uploadFileBase64(chatId: Int64, base64Data: String, fileName: String, fileType: String, replyToId: Int64? = nil) async throws -> Message {
        guard let url = URL(string: "\(baseURL)/api/messenger/chats/\(chatId)/base64upload") else {
            throw MessengerError.invalidURL
        }
        
        let body: [String: Any] = [
            "type": fileType,
            "filename": fileName,
            "data": base64Data,
            "reply_to_id": replyToId as Any
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = try makeRequest(url: url, method: "POST", body: bodyData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.fileUploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadFileResponse.self, from: data)
        return uploadResponse.message
    }
    
    // MARK: - Read Receipt
    
    func markAsRead(messageId: Int64) async throws {
        guard let url = URL(string: "\(baseURL)/api/messenger/read/\(messageId)") else {
            throw MessengerError.invalidURL
        }
        
        let request = try makeRequest(url: url, method: "POST")
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.invalidResponse
        }
    }
    
    // MARK: - Delete Message
    
    func deleteMessage(messageId: Int64) async throws {
        guard let url = URL(string: "\(baseURL)/api/messenger/messages/\(messageId)") else {
            throw MessengerError.invalidURL
        }
        
        let request = try makeRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.invalidResponse
        }
    }
    
    // MARK: - Create Chat
    
    func createPersonalChat(userId: Int64) async throws -> Chat {
        guard let url = URL(string: "\(baseURL)/api/messenger/chats/personal") else {
            throw MessengerError.invalidURL
        }
        
        let body: [String: Any] = [
            "user_id": userId
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = try makeRequest(url: url, method: "POST", body: bodyData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.invalidResponse
        }
        
        let createResponse = try JSONDecoder().decode(CreateChatResponse.self, from: data)
        return createResponse.chat
    }
    
    func createGroupChat(title: String, userIds: [Int64]) async throws -> Chat {
        guard let url = URL(string: "\(baseURL)/api/messenger/chats/group") else {
            throw MessengerError.invalidURL
        }
        
        let body: [String: Any] = [
            "title": title,
            "user_ids": userIds
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = try makeRequest(url: url, method: "POST", body: bodyData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessengerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MessengerError.invalidResponse
        }
        
        let createResponse = try JSONDecoder().decode(CreateChatResponse.self, from: data)
        return createResponse.chat
    }
    
    // MARK: - File Access
    
    func getFileURL(chatId: Int64, filePath: String) -> URL? {
        // Use session key instead of JWT token for file access
        guard let sessionKey = try? KeychainManager.getSessionKey() else {
            // Fallback without token
            return URL(string: "https://k-connect.ru/apiMes/messenger/files/\(chatId)/\(filePath)")
        }
        // Use apiMes instead of api, and add session key as token query parameter
        return URL(string: "https://k-connect.ru/apiMes/messenger/files/\(chatId)/\(filePath)?token=\(sessionKey)")
    }
}

