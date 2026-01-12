import Foundation
import UIKit

class PostService {
    static let shared = PostService()
    private let baseURL = "https://k-connect.ru"
    
    private var userAgent: String {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let scale = window.screen.scale
            return "KConnect-iOS/1.2.5 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/\(String(format: "%.1f", scale)))"
        }
        return "KConnect-iOS/1.2.5 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/3.0)"
    }
    
    private init() {}
    
    func createPost(
        content: String? = nil,
        images: [UIImage] = [],
        video: Data? = nil,
        isNsfw: Bool = false,
        music: MusicTrack? = nil,
        poll: CreatePollData? = nil,
        postType: String? = nil,
        recipientId: Int64? = nil
    ) async throws -> Post {
        guard let token = try KeychainManager.getToken() else {
            throw PostError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PostError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/posts/create") else {
            throw PostError.invalidURL
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
        
        print("📝 CREATE POST DEBUG:")
        print("  Content: '\(content ?? "nil")'")
        print("  Images count: \(images.count)")
        print("  Video: \(video != nil ? "present (\(video!.count) bytes)" : "nil")")
        print("  isNsfw: \(isNsfw)")
        print("  Music: \(music != nil ? "present" : "nil")")
        print("  Poll: \(poll != nil ? "present" : "nil")")
        print("  PostType: \(postType ?? "post")")
        print("  RecipientId: \(recipientId?.description ?? "nil")")
        
        if let content = content, !content.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
            body.append(content.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            print("  ✅ Sent content: '\(content)'")
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"is_nsfw\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(isNsfw)".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        print("  ✅ Sent is_nsfw: \(isNsfw)")
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append((postType ?? "post").data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        print("  ✅ Sent type: \(postType ?? "post")")
        
        if let recipientId = recipientId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"recipient_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(recipientId)".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            print("  ✅ Sent recipient_id: \(recipientId)")
        }
        
        if let music = music {
            do {
                let musicArray = [music]
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                let musicJSON = try encoder.encode(musicArray)
                
                if let musicString = String(data: musicJSON, encoding: .utf8) {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"music\"\r\n\r\n".data(using: .utf8)!)
                    body.append(musicString.data(using: .utf8)!)
                    body.append("\r\n".data(using: .utf8)!)
                    print("  ✅ Sent music: \(musicString.prefix(100))...")
                }
            } catch {
                print("❌ Error encoding music: \(error)")
            }
        }
        
        if let poll = poll {
            print("📊 POLL DATA DEBUG:")
            print("  Question: '\(poll.question)'")
            print("  All options count: \(poll.options.count)")
            print("  All options: \(poll.options)")
            
            // Poll question
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"poll_question\"\r\n\r\n".data(using: .utf8)!)
            body.append(poll.question.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            print("  ✅ Sent poll_question: '\(poll.question)'")
            
            // Poll options - send as JSON array
            let validOptions = poll.options.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            print("  Valid options count: \(validOptions.count)")
            print("  Valid options: \(validOptions)")
            
            if validOptions.count < 2 {
                print("  ❌ ERROR: Less than 2 valid options!")
            }
            
            // Encode options as JSON array
            do {
                let optionsJSON = try JSONEncoder().encode(validOptions)
                if let optionsString = String(data: optionsJSON, encoding: .utf8) {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"poll_options\"\r\n\r\n".data(using: .utf8)!)
                    body.append(optionsString.data(using: .utf8)!)
                    body.append("\r\n".data(using: .utf8)!)
                    print("  ✅ Sent poll_options: \(optionsString)")
                }
            } catch {
                print("  ❌ Error encoding poll options: \(error)")
            }
            
            // Poll settings
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"poll_is_multiple\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(poll.isMultipleChoice)".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            print("  ✅ Sent poll_is_multiple: \(poll.isMultipleChoice)")
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"poll_is_anonymous\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(poll.isAnonymous)".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            print("  ✅ Sent poll_is_anonymous: \(poll.isAnonymous)")
            
            // Calculate and send expiration date only if temporary
            if poll.isTemporary {
                let expirationDate = Calendar.current.date(byAdding: .day, value: poll.expiresInDays, to: Date()) ?? Date()
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let expirationString = formatter.string(from: expirationDate)
                
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"poll_expires_at\"\r\n\r\n".data(using: .utf8)!)
                body.append(expirationString.data(using: .utf8)!)
                body.append("\r\n".data(using: .utf8)!)
                print("  ✅ Sent poll_expires_at: \(expirationString) (expires in \(poll.expiresInDays) days)")
            } else {
                print("  ✅ Poll is permanent (no expiration)")
            }
        }
        
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("  ❌ Failed to encode image[\(index)]")
                continue
            }
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images[\(index)]\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            print("  ✅ Sent images[\(index)]: \(imageData.count) bytes")
        }
        
        if let video = video {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(video)
            body.append("\r\n".data(using: .utf8)!)
            print("  ✅ Sent video: \(video.count) bytes")
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🟢 CREATE POST REQUEST: URL: \(url.absoluteString) Method: POST Headers: [\"Authorization\": \"Bearer \(token.prefix(20))...\", \"User-Agent\": \"\(userAgent)\", \"X-Mobile-Client\": \"true\", \"X-Session-Key\": \"\(sessionKey.prefix(20))...\"] Body size: \(body.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostError.invalidResponse
        }
        
        print("🟢 CREATE POST RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let createResponse = try decoder.decode(CreatePostResponse.self, from: data)
                print("🟢 CREATE POST SUCCESS: post_id=\(createResponse.post.id)")
                return createResponse.post
            } catch {
                print("❌ JSON Decoding Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response body: \(jsonString)")
                }
                throw PostError.decodingError(error)
            }
        } else if httpResponse.statusCode == 429 {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw PostError.rateLimit
        } else {
            print("❌ CREATE POST ERROR: Status Code: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw PostError.serverError(httpResponse.statusCode)
        }
    }
}

struct CreatePostResponse: Codable {
    let success: Bool
    let post: Post
}

enum PostError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case rateLimit
    
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
        case .rateLimit:
            return "Превышен лимит создания постов"
        }
    }
}

