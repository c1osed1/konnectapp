//
//  ChatViewModel.swift
//  konnectapp
//
//  ViewModel for managing a single chat
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var error: String?
    @Published var typingUsers: [Int64: String] = [:] // [userId: username]
    @Published var hasMoreMessages: Bool = true
    
    let chatId: Int64
    private var currentPage: Int = 1
    private var oldestMessageId: Int64?
    
    private var cancellables = Set<AnyCancellable>()
    private let webSocketService = MessengerWebSocketService.shared
    private let messengerService = MessengerService.shared
    
    init(chatId: Int64) {
        self.chatId = chatId
        setupWebSocketCallbacks()
        
        // If WebSocket is already connected, request messages immediately
        if webSocketService.isConnected {
            webSocketService.getMessages(chatId: chatId, limit: 50, beforeId: nil, forceRefresh: false)
        }
    }
    
    func loadMessages(forceRefresh: Bool = false) {
        Task {
            await MainActor.run {
                if messages.isEmpty {
                    isLoading = true
                } else {
                    isLoadingMore = true
                }
                error = nil
            }
            
            // Try REST API first
            do {
                let beforeId = forceRefresh ? nil : oldestMessageId
                let loadedMessages = try await messengerService.getMessages(
                    chatId: chatId,
                    limit: 50,
                    beforeId: beforeId,
                    forceRefresh: forceRefresh
                )
                
                await MainActor.run {
                    if forceRefresh || self.messages.isEmpty {
                        self.messages = loadedMessages.reversed()
                    } else {
                        self.messages.insert(contentsOf: loadedMessages.reversed(), at: 0)
                    }
                    
                    if let oldest = loadedMessages.first {
                        self.oldestMessageId = oldest.id
                    }
                    
                    self.hasMoreMessages = loadedMessages.count >= 50
                    self.isLoading = false
                    self.isLoadingMore = false
                }
                
                // Mark messages as read
                if let newestMessage = loadedMessages.last {
                    markAsRead(messageId: newestMessage.id)
                }
            } catch {
                print("⚠️ REST API error loading messages (will use WebSocket): \(error)")
                
                // If REST fails, use WebSocket
                if webSocketService.isConnected {
                    // Request messages via WebSocket
                    webSocketService.getMessages(
                        chatId: chatId,
                        limit: 50,
                        beforeId: forceRefresh ? nil : oldestMessageId,
                        forceRefresh: forceRefresh
                    )
                    // Keep isLoading = true until WebSocket responds via callback
                } else {
                    // WebSocket not connected, try to connect
                    webSocketService.connect()
                    // WebSocket will automatically request messages after connection
                    // But we need to request manually after connection
                    // For now, keep isLoading = true
                }
            }
        }
    }
    
    func sendMessage(text: String, replyToId: Int64? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Optimistically add message
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let tempMessage = Message(
            id: Int64.random(in: 1000000...9999999), // Temporary ID
            chat_id: chatId,
            sender_id: AuthManager.shared.currentUser?.id ?? 0,
            sender_name: AuthManager.shared.currentUser?.name ?? "",
            sender_username: AuthManager.shared.currentUser?.username,
            message_type: "text",
            content: text,
            original_filename: nil,
            created_at: dateFormatter.string(from: Date()),
            edited_at: nil,
            reply_to_id: replyToId,
            is_read: 0,
            read_count: nil,
            is_from_moderator: false,
            is_encrypted: nil,
            forwarded_from_id: nil,
            date_key: nil,
            sticker_data: nil,
            photo_url: nil,
            video_url: nil,
            audio_url: nil,
            file_size: nil,
            mime_type: nil
        )
        
        Task { @MainActor in
            messages.append(tempMessage)
        }
        
        // Send via WebSocket
        if webSocketService.isConnected {
            webSocketService.sendTextMessage(chatId: chatId, text: text, replyToId: replyToId)
        } else {
            // Fallback to REST API
            Task {
                do {
                    let sentMessage = try await messengerService.sendMessage(
                        chatId: chatId,
                        text: text,
                        replyToId: replyToId
                    )
                    await MainActor.run {
                        if let index = self.messages.firstIndex(where: { $0.id == tempMessage.id }) {
                            self.messages[index] = sentMessage
                        }
                    }
                } catch {
                    await MainActor.run {
                        // Remove temp message on error
                        self.messages.removeAll { $0.id == tempMessage.id }
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func sendPhoto(imageData: Data, fileName: String, replyToId: Int64? = nil) {
        Task {
            do {
                let message = try await messengerService.uploadFile(
                    chatId: chatId,
                    fileData: imageData,
                    fileName: fileName,
                    mimeType: "image/jpeg",
                    messageType: "photo",
                    replyToId: replyToId
                )
                await MainActor.run {
                    self.messages.append(message)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func sendVideo(videoData: Data, fileName: String, replyToId: Int64? = nil) {
        Task {
            do {
                let message = try await messengerService.uploadFile(
                    chatId: chatId,
                    fileData: videoData,
                    fileName: fileName,
                    mimeType: "video/mp4",
                    messageType: "video",
                    replyToId: replyToId
                )
                await MainActor.run {
                    self.messages.append(message)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func sendAudio(audioData: Data, fileName: String, replyToId: Int64? = nil) {
        Task {
            do {
                let message = try await messengerService.uploadFile(
                    chatId: chatId,
                    fileData: audioData,
                    fileName: fileName,
                    mimeType: "audio/mpeg",
                    messageType: "audio",
                    replyToId: replyToId
                )
                await MainActor.run {
                    self.messages.append(message)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func startTyping() {
        webSocketService.sendTypingStart(chatId: chatId)
    }
    
    func stopTyping() {
        webSocketService.sendTypingEnd(chatId: chatId)
    }
    
    func markAsRead(messageId: Int64) {
        Task {
            do {
                try await messengerService.markAsRead(messageId: messageId)
                if webSocketService.isConnected {
                    webSocketService.markAsRead(messageId: messageId, chatId: chatId)
                }
            } catch {
                print("❌ Error marking message as read: \(error)")
            }
        }
    }
    
    func deleteMessage(messageId: Int64) {
        Task {
            do {
                try await messengerService.deleteMessage(messageId: messageId)
                if webSocketService.isConnected {
                    webSocketService.deleteMessage(messageId: messageId, chatId: chatId)
                }
                await MainActor.run {
                    self.messages.removeAll { $0.id == messageId }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    private func setupWebSocketCallbacks() {
        webSocketService.onMessagesReceived = { [weak self] receivedChatId, receivedMessages in
            guard receivedChatId == self?.chatId else { return }
            Task { @MainActor in
                self?.messages = receivedMessages.reversed()
                self?.isLoading = false
            }
        }
        
        webSocketService.onNewMessage = { [weak self] receivedChatId, message in
            guard receivedChatId == self?.chatId else { return }
            Task { @MainActor in
                // Don't add duplicate messages
                if !self!.messages.contains(where: { $0.id == message.id }) {
                    self!.messages.append(message)
                }
                // Mark as read
                self?.markAsRead(messageId: message.id)
            }
        }
        
        webSocketService.onMessageSent = { [weak self] receivedChatId, messageId, clientMessageId in
            guard receivedChatId == self?.chatId else { return }
            // Message was sent successfully, could update UI if needed
        }
        
        webSocketService.onTypingIndicator = { [weak self] receivedChatId, userId, username, isTyping in
            guard receivedChatId == self?.chatId else { return }
            Task { @MainActor in
                if isTyping {
                    self?.typingUsers[userId] = username
                } else {
                    self?.typingUsers.removeValue(forKey: userId)
                }
            }
        }
        
        webSocketService.onMessageRead = { [weak self] receivedChatId, messageId in
            guard receivedChatId == self?.chatId else { return }
            Task { @MainActor in
                if let index = self?.messages.firstIndex(where: { $0.id == messageId }) {
                    var message = self!.messages[index]
                    let updatedMessage = Message(
                        id: message.id,
                        chat_id: message.chat_id,
                        sender_id: message.sender_id,
                        sender_name: message.sender_name,
                        sender_username: message.sender_username,
                        message_type: message.message_type,
                        content: message.content,
                        original_filename: message.original_filename,
                        created_at: message.created_at,
                        edited_at: message.edited_at,
                        reply_to_id: message.reply_to_id,
                        is_read: 1,
                        read_count: message.read_count,
                        is_from_moderator: message.is_from_moderator,
                        is_encrypted: message.is_encrypted,
                        forwarded_from_id: message.forwarded_from_id,
                        date_key: message.date_key,
                        sticker_data: message.sticker_data,
                        photo_url: message.photo_url,
                        video_url: message.video_url,
                        audio_url: message.audio_url,
                        file_size: message.file_size,
                        mime_type: message.mime_type
                    )
                    self!.messages[index] = updatedMessage
                }
            }
        }
        
        webSocketService.onMessageDeleted = { [weak self] receivedChatId, messageId in
            guard receivedChatId == self?.chatId else { return }
            Task { @MainActor in
                self?.messages.removeAll { $0.id == messageId }
            }
        }
    }
}

