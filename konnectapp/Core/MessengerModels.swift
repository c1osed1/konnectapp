//
//  MessengerModels.swift
//  konnectapp
//
//  Created for Messenger functionality
//

import Foundation

// MARK: - Chat Models

struct Chat: Codable, Identifiable, Equatable, Hashable {
    let id: Int64
    let title: String
    let chat_type: String // "personal" or "group"
    let is_group: Bool
    let avatar: String?
    let created_at: String? // ISO 8601
    let updated_at: String // ISO 8601
    let is_encrypted: Int? // 0 or 1
    let last_message: LastMessage?
    let unread_count: Int
    let members: [ChatMember]?
    
    // Computed property for full avatar URL
    var fullAvatarURL: String? {
        guard let avatar = avatar else { return nil }
        if avatar.hasPrefix("http://") || avatar.hasPrefix("https://") {
            return avatar
        }
        // Relative URL - convert to full URL
        if avatar.hasPrefix("/") {
            return "https://k-connect.ru\(avatar)"
        }
        return "https://k-connect.ru/\(avatar)"
    }
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct LastMessage: Codable, Hashable {
    let id: Int64
    let sender_id: Int64?
    let message_type: String?
    let content: String
    let created_at: String // ISO 8601
    let is_read: Int? // 0 or 1 for read status
}

struct ChatMember: Codable, Identifiable, Hashable {
    let user_id: Int64
    let name: String
    let username: String
    let avatar: String?
    let is_online: Int? // 0 or 1
    let last_active: String? // ISO 8601
    let role: String? // "member", "admin", etc.
    let joined_at: String? // ISO 8601
    let account_type: String? // "user", "channel", etc.
    
    var id: Int64 { user_id }
    
    // Computed property for convenience
    var isOnline: Bool {
        return (is_online ?? 0) > 0
    }
}

// MARK: - Message Models

struct Message: Codable, Identifiable, Equatable {
    let id: Int64
    let chat_id: Int64?
    let sender_id: Int64
    let sender_name: String
    let sender_username: String?
    let message_type: String // "text", "photo", "video", "audio", "sticker"
    let content: String
    let original_filename: String?
    let created_at: String // ISO 8601
    let edited_at: String?
    let reply_to_id: Int64?
    let is_read: Int?
    let read_count: Int?
    let is_from_moderator: Bool?
    let is_encrypted: Int?
    let forwarded_from_id: Int64?
    let date_key: String?
    let sticker_data: StickerData?
    let photo_url: String?
    let video_url: String?
    let audio_url: String?
    let file_size: Int64?
    let mime_type: String?
    
    // Computed properties for full URLs
    var fullPhotoURL: String? {
        guard let chat_id = chat_id else { return nil }
        let filePath: String
        if let photo_url = photo_url {
            filePath = photo_url
        } else if message_type == "photo" && content.hasPrefix("photo/") {
            filePath = content
        } else {
            return nil
        }
        return MessengerService.shared.getFileURL(chatId: chat_id, filePath: filePath)?.absoluteString
    }
    
    var fullVideoURL: String? {
        guard let chat_id = chat_id else { return nil }
        let filePath: String
        if let video_url = video_url {
            filePath = video_url
        } else if message_type == "video" && content.hasPrefix("video/") {
            filePath = content
        } else {
            return nil
        }
        return MessengerService.shared.getFileURL(chatId: chat_id, filePath: filePath)?.absoluteString
    }
    
    var fullAudioURL: String? {
        guard let chat_id = chat_id else { return nil }
        let filePath: String
        if let audio_url = audio_url {
            filePath = audio_url
        } else if message_type == "audio" && content.hasPrefix("audio/") {
            filePath = content
        } else {
            return nil
        }
        return MessengerService.shared.getFileURL(chatId: chat_id, filePath: filePath)?.absoluteString
    }
    
    // Проверка, является ли сообщение прочитанным
    var isRead: Bool {
        return (is_read ?? 0) > 0 || (read_count ?? 0) > 0
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

struct StickerData: Codable {
    let pack_id: Int
    let sticker_id: Int
    let name: String
    let pack_name: String
    let emoji: String
    let file_path: String
    let mime_type: String
    let width: Int
    let height: Int
    
    var fullURL: String {
        return "https://k-connect.ru/api/messenger/stickers/\(pack_id)/\(sticker_id)"
    }
}

// MARK: - WebSocket Message Types

enum WebSocketMessageType: String, Codable {
    case auth
    case connected
    case error
    case ping
    case pong
    case get_chats
    case chats
    case get_messages
    case messages
    case send_message
    case message_sent
    case new_message
    case typing_start
    case typing_end
    case typing_indicator
    case typing_indicator_end
    case read_receipt
    case read_receipt_response
    case message_read
    case message_deleted
    case delivery_confirmation
    case delivery_confirmation_ack
    case unread_counts
    case connection_stats
}

// MARK: - WebSocket Request Models

struct WebSocketAuthRequest: Codable {
    let type: String
    let token: String
    let device_id: String?
    let client_info: ClientInfo?
    
    init(token: String, device_id: String? = nil, client_info: ClientInfo? = nil) {
        self.type = "auth"
        self.token = token
        self.device_id = device_id
        self.client_info = client_info
    }
}

struct ClientInfo: Codable {
    let platform: String
    let version: String
    let device: String
}

struct WebSocketGetChatsRequest: Codable {
    let type: String
    
    init() {
        self.type = "get_chats"
    }
}

struct WebSocketGetMessagesRequest: Codable {
    let type: String
    let chat_id: Int64
    let limit: Int?
    let before_id: Int64?
    let force_refresh: Bool?
    
    init(chat_id: Int64, limit: Int? = nil, before_id: Int64? = nil, force_refresh: Bool? = nil) {
        self.type = "get_messages"
        self.chat_id = chat_id
        self.limit = limit
        self.before_id = before_id
        self.force_refresh = force_refresh
    }
}

struct WebSocketSendMessageRequest: Codable {
    let type: String
    let chatId: Int64
    let text: String
    let replyToId: Int64?
    let clientMessageId: String?
    let tempId: String?
    
    init(chatId: Int64, text: String, replyToId: Int64? = nil, clientMessageId: String? = nil, tempId: String? = nil) {
        self.type = "send_message"
        self.chatId = chatId
        self.text = text
        self.replyToId = replyToId
        self.clientMessageId = clientMessageId
        self.tempId = tempId
    }
}

struct WebSocketTypingStartRequest: Codable {
    let type: String
    let chatId: Int64
    
    init(chatId: Int64) {
        self.type = "typing_start"
        self.chatId = chatId
    }
}

struct WebSocketTypingEndRequest: Codable {
    let type: String
    let chatId: Int64
    
    init(chatId: Int64) {
        self.type = "typing_end"
        self.chatId = chatId
    }
}

struct WebSocketReadReceiptRequest: Codable {
    let type: String
    let messageId: Int64
    let chatId: Int64
    
    init(messageId: Int64, chatId: Int64) {
        self.type = "read_receipt"
        self.messageId = messageId
        self.chatId = chatId
    }
}

struct WebSocketDeleteMessageRequest: Codable {
    let type: String
    let messageId: Int64
    let chatId: Int64
    
    init(messageId: Int64, chatId: Int64) {
        self.type = "message_deleted"
        self.messageId = messageId
        self.chatId = chatId
    }
}

struct WebSocketDeliveryConfirmationRequest: Codable {
    let type: String
    let delivery_id: String
    let messageId: Int64
    let chatId: Int64
    
    init(delivery_id: String, messageId: Int64, chatId: Int64) {
        self.type = "delivery_confirmation"
        self.delivery_id = delivery_id
        self.messageId = messageId
        self.chatId = chatId
    }
}

// MARK: - WebSocket Response Models

struct WebSocketConnectedResponse: Codable {
    let type: String
    let message: String?
    let user: WebSocketUser?
    let device_id: String?
    let connection_info: ConnectionInfo?
    let server_stats: ServerStats?
}

struct WebSocketUser: Codable {
    let id: Int64
    let name: String
    let username: String
}

struct ConnectionInfo: Codable {
    let active_devices: Int?
    let ping_interval: Int?
    let server_time: String?
    let connection_id: String?
}

struct ServerStats: Codable {
    let total_connections: Int?
    let active_users: Int?
}

struct WebSocketErrorResponse: Codable {
    let type: String
    let message: String
    let code: String?
    let reconnect: Bool?
}

struct WebSocketPingMessage: Codable {
    let type: String
    let timestamp: Double
    let ping_id: String
}

struct WebSocketPongMessage: Codable {
    let type: String
    let timestamp: Double
    let ping_id: String
}

struct WebSocketChatsResponse: Codable {
    let type: String
    let chats: [Chat]
    let timezone: String?
}

struct WebSocketMessagesResponse: Codable {
    let type: String
    let chat_id: Int64
    let messages: [Message]
    let timezone: String?
    let has_moderator_messages: Bool?
    let cache_info: CacheInfo?
}

struct CacheInfo: Codable {
    let cached: Bool
    let cache_key: String?
    let expires_at: String?
}

struct WebSocketNewMessageResponse: Codable {
    let type: String
    let chatId: Int64
    let message: Message
    let origin_device_id: String?
    let client_message_id: String?
    let temp_id: String?
    let requires_delivery_confirmation: Bool?
}

struct WebSocketMessageSentResponse: Codable {
    let type: String
    let messageId: Int64
    let clientMessageId: String?
    let tempId: String?
    let chatId: Int64
    let timestamp: String
    let device_id: String?
    let delivery_status: String
}

struct WebSocketTypingIndicatorResponse: Codable {
    let type: String
    let chatId: Int64
    let userId: Int64
    let username: String
    let device_id: String?
}

struct WebSocketUnreadCountsResponse: Codable {
    let type: String
    let counts: [String: Int] // [chat_id: count]
}

// MARK: - REST API Response Models

struct ChatsResponse: Codable {
    let success: Bool?
    let chats: [Chat]
    let timezone: String?
}

struct ChatResponse: Codable {
    let success: Bool
    let chat: Chat
}

struct MessagesResponse: Codable {
    let success: Bool
    let messages: [Message]
    let timezone: String?
    let has_moderator_messages: Bool?
    let cache_info: CacheInfo?
}

struct SendMessageResponse: Codable {
    let success: Bool
    let message: Message
    let timezone: String?
}

struct UploadFileResponse: Codable {
    let success: Bool
    let message: Message
    let timezone: String?
}

struct CreateChatResponse: Codable {
    let success: Bool
    let chat: Chat
}

// MARK: - Messenger Errors

enum MessengerError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case websocketConnectionFailed
    case websocketAuthFailed
    case messageSendFailed
    case fileUploadFailed
    case invalidFileType
    case fileTooLarge
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Требуется авторизация"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .websocketConnectionFailed:
            return "Ошибка подключения к WebSocket"
        case .websocketAuthFailed:
            return "Ошибка аутентификации WebSocket"
        case .messageSendFailed:
            return "Ошибка отправки сообщения"
        case .fileUploadFailed:
            return "Ошибка загрузки файла"
        case .invalidFileType:
            return "Неподдерживаемый тип файла"
        case .fileTooLarge:
            return "Файл слишком большой"
        case .rateLimitExceeded:
            return "Превышен лимит запросов"
        }
    }
}

