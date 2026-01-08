import Foundation
import UIKit

class CommentService {
    static let shared = CommentService()
    
    private init() {}
    
    private var userAgent: String {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let scale = window.screen.scale
            return "KConnect-iOS/1.2.3 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/\(String(format: "%.1f", scale)))"
        }
        return "KConnect-iOS/1.2.3 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/3.0)"
    }
    
    func getPostDetail(postId: Int64, includeComments: Bool = false) async throws -> PostDetailResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        var urlString = "https://k-connect.ru/api/posts/\(postId)"
        if includeComments {
            urlString += "?include_comments=true"
        }
        
        guard let url = URL(string: urlString) else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 POST DETAIL REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 POST DETAIL RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let response = try decoder.decode(PostDetailResponse.self, from: data)
            if let post = response.post {
                print("🟢 POST DETAIL DECODED: id=\(post.id), type=\(post.type ?? "nil"), has_original_post=\(post.original_post != nil)")
                if let originalPost = post.original_post {
                    print("🟢 ORIGINAL POST: id=\(originalPost.id), content=\(originalPost.content ?? "nil"), has_music=\(originalPost.music != nil && !(originalPost.music?.isEmpty ?? true))")
                }
            }
            return response
        } catch {
            print("❌ POST DETAIL DECODING ERROR: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Key not found: \(key.stringValue) at \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) at \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type) at \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted at \(context.codingPath): \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    func getComments(postId: Int64, page: Int = 1, limit: Int = 20) async throws -> CommentsResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/posts/\(postId)/comments?page=\(page)&limit=\(limit)") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 COMMENTS REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 COMMENTS RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🟢 COMMENTS RESPONSE BODY (first 1000 chars): \(responseString.prefix(1000))")
        }
        
        // Decode CommentsResponse with custom handling for Pagination
        do {
            // First decode the main structure
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let commentsArray = json?["comments"] as? [[String: Any]] else {
                throw CommentError.invalidResponse
            }
            
            // Decode comments with convertFromSnakeCase
            let commentsDecoder = JSONDecoder()
            commentsDecoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // Логируем сырые данные для отладки
            for (index, commentDict) in commentsArray.enumerated() {
                if let replies = commentDict["replies"] as? [[String: Any]] {
                    print("🟢 COMMENT \(index) has \(replies.count) replies in raw JSON")
                } else if let repliesCount = commentDict["replies_count"] as? Int, repliesCount > 0 {
                    print("🟡 COMMENT \(index) has replies_count=\(repliesCount) but no replies array")
                }
            }
            
            let commentsData = try JSONSerialization.data(withJSONObject: commentsArray)
            let comments = try commentsDecoder.decode([Comment].self, from: commentsData)
            
            // Логируем replies для каждого комментария после декодирования
            for comment in comments {
                if let repliesCount = comment.replies_count, repliesCount > 0 {
                    print("🟢 COMMENT \(comment.id) has \(repliesCount) replies_count, decoded replies: \(comment.replies?.count ?? 0)")
                    if let replies = comment.replies {
                        for reply in replies {
                            print("  - Reply \(reply.id): \(reply.content ?? "no content")")
                        }
                    } else {
                        print("  - ⚠️ replies is nil!")
                    }
                }
            }
            
            // Decode pagination separately without convertFromSnakeCase
            var pagination: Pagination? = nil
            if let paginationDict = json?["pagination"] as? [String: Any] {
                let paginationData = try JSONSerialization.data(withJSONObject: paginationDict)
                let paginationDecoder = JSONDecoder()
                paginationDecoder.keyDecodingStrategy = .useDefaultKeys
                pagination = try paginationDecoder.decode(Pagination.self, from: paginationData)
            }
            
            let response = CommentsResponse(comments: comments, pagination: pagination)
            print("🟢 COMMENTS DECODED: \(response.comments.count) comments")
            return response
        } catch {
            print("❌ COMMENTS DECODING ERROR: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Key not found: \(key.stringValue) at \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) at \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type) at \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted at \(context.codingPath): \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    func createComment(postId: Int64, content: String?, image: UIImage?, parentCommentId: Int64? = nil) async throws -> CreateCommentResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/posts/\(postId)/comments") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if let content = content, !content.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
            body.append(content.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        if let parentCommentId = parentCommentId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"parent_comment_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(parentCommentId)".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("🔵 CREATE COMMENT REQUEST: URL: \(url.absoluteString) Content length: \(body.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 CREATE COMMENT RESPONSE: Status Code: \(httpResponse.statusCode) Data size: \(data.count) bytes")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🟢 CREATE COMMENT RESPONSE BODY: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if httpResponse.statusCode == 429 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Rate limit error: \(errorString)")
                }
                throw CommentError.rateLimit
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            // API возвращает {"comment": {...}} без поля success
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let commentDict = json["comment"] as? [String: Any] {
                let commentData = try JSONSerialization.data(withJSONObject: commentDict)
                let comment = try decoder.decode(Comment.self, from: commentData)
                print("🟢 CREATE COMMENT DECODED: success=true, comment_id=\(comment.id)")
                return CreateCommentResponse(success: true, comment: comment, error: nil)
            }
            
            // Fallback: попытка стандартного декодирования
            let response = try decoder.decode(CreateCommentResponse.self, from: data)
            print("🟢 CREATE COMMENT DECODED: success=\(response.success ?? false)")
            return response
        } catch {
            print("❌ CREATE COMMENT DECODING ERROR: \(error)")
            throw error
        }
    }
    
    func createReply(commentId: Int64, content: String?, image: UIImage?, parentReplyId: Int64? = nil) async throws -> CreateReplyResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/comments/\(commentId)/replies") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        // Используем JSON для replies
        var jsonBody: [String: Any] = [:]
        if let content = content, !content.isEmpty {
            jsonBody["content"] = content
        }
        // parent_reply_id всегда отправляем (null если нет)
        jsonBody["parent_reply_id"] = parentReplyId ?? NSNull()
        
        // Если есть изображение, используем multipart/form-data
        if let image = image {
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            if let content = content, !content.isEmpty {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
                body.append(content.data(using: .utf8)!)
                body.append("\r\n".data(using: .utf8)!)
            }
            
            // parent_reply_id всегда отправляем (null если нет)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"parent_reply_id\"\r\n\r\n".data(using: .utf8)!)
            if let parentReplyId = parentReplyId {
                body.append("\(parentReplyId)".data(using: .utf8)!)
            }
            body.append("\r\n".data(using: .utf8)!)
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
        } else {
            // Используем JSON если нет изображения
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        }
        
        print("🔵 CREATE REPLY REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 CREATE REPLY RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🟢 CREATE REPLY RESPONSE BODY: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if httpResponse.statusCode == 429 {
                throw CommentError.rateLimit
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // API возвращает {"reply": {...}}
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let replyDict = json["reply"] as? [String: Any] {
            let replyData = try JSONSerialization.data(withJSONObject: replyDict)
            let reply = try decoder.decode(Reply.self, from: replyData)
            print("🟢 CREATE REPLY DECODED: success=true, reply_id=\(reply.id)")
            return CreateReplyResponse(success: true, reply: reply, error: nil)
        }
        
        // Fallback
        do {
            let response = try decoder.decode(CreateReplyResponse.self, from: data)
            return response
        } catch {
            print("❌ CREATE REPLY DECODING ERROR: \(error)")
            throw error
        }
    }
    
    func likeComment(commentId: Int64) async throws -> PostLikeResponse {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/comments/\(commentId)/like") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🔵 LIKE COMMENT REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 LIKE COMMENT RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PostLikeResponse.self, from: data)
    }
    
    func deleteComment(commentId: Int64) async throws {
        guard let token = try KeychainManager.getToken() else {
            throw CommentError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw CommentError.notAuthenticated
        }
        
        guard let url = URL(string: "https://k-connect.ru/api/comments/\(commentId)/delete") else {
            throw CommentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("🔵 DELETE COMMENT REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommentError.invalidResponse
        }
        
        print("🟢 DELETE COMMENT RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🟢 DELETE COMMENT RESPONSE BODY: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw CommentError.unauthorized
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw CommentError.serverError(httpResponse.statusCode)
        }
        
        // Проверяем успешность удаления
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool,
           success {
            print("🟢 Comment deleted successfully")
        }
    }
}

enum CommentError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case rateLimit
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "Не авторизован"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .unauthorized:
            return "Сессия истекла"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .rateLimit:
            return "Слишком много запросов. Подождите немного."
        }
    }
}

