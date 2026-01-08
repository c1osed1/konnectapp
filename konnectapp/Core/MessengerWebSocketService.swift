//
//  MessengerWebSocketService.swift
//  konnectapp
//
//  WebSocket service for real-time messaging
//

import Foundation
import Combine
import UIKit

class MessengerWebSocketService: NSObject, ObservableObject {
    static let shared = MessengerWebSocketService()
    
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    
    // Cache for chats to make them available immediately when ChatsViewModel is created
    @Published var cachedChats: [Chat] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var shouldReconnect = true
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // Callbacks
    var onChatsReceived: (([Chat]) -> Void)?
    var onMessagesReceived: ((Int64, [Message]) -> Void)?
    var onNewMessage: ((Int64, Message) -> Void)?
    var onMessageSent: ((Int64, Int64, String?) -> Void)?
    var onTypingIndicator: ((Int64, Int64, String, Bool) -> Void)?
    var onMessageRead: ((Int64, Int64) -> Void)?
    var onMessageDeleted: ((Int64, Int64) -> Void)?
    var onUnreadCounts: (([String: Int]) -> Void)?
    var onError: ((String, String?) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard !isConnected else { return }
        
        guard let sessionKey = try? KeychainManager.getSessionKey() else {
            print("❌ No session key available")
            connectionError = "Нет ключа сессии"
            return
        }
        
        let urlString = "wss://k-connect.ru/ws/messenger"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid WebSocket URL")
            connectionError = "Неверный URL"
            return
        }
        
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage()
        sendAuth(sessionKey: sessionKey)
        
        startPingTimer()
    }
    
    func disconnect() {
        shouldReconnect = false
        pingTimer?.invalidate()
        pingTimer = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        
        Task { @MainActor in
            isConnected = false
        }
    }
    
    private func reconnect() {
        guard shouldReconnect, reconnectAttempts < maxReconnectAttempts else {
            print("❌ Max reconnect attempts reached")
            return
        }
        
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 30.0) // Exponential backoff, max 30s
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    // MARK: - Authentication
    
    private func sendAuth(sessionKey: String) {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        let authRequest = WebSocketAuthRequest(
            token: sessionKey,
            device_id: deviceId,
            client_info: ClientInfo(
                platform: "iOS",
                version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.3",
                device: UIDevice.current.model
            )
        )
        
        sendMessage(authRequest)
    }
    
    // MARK: - Message Sending
    
    func sendMessage<T: Codable>(_ message: T) {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("❌ Failed to convert data to string")
                return
            }
            
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask.send(message) { error in
                if let error = error {
                    print("❌ Error sending message: \(error)")
                }
            }
        } catch {
            print("❌ Error encoding message: \(error)")
        }
    }
    
    func getChats() {
        sendMessage(WebSocketGetChatsRequest())
    }
    
    func getMessages(chatId: Int64, limit: Int? = 50, beforeId: Int64? = nil, forceRefresh: Bool = false) {
        let request = WebSocketGetMessagesRequest(
            chat_id: chatId,
            limit: limit,
            before_id: beforeId,
            force_refresh: forceRefresh
        )
        sendMessage(request)
    }
    
    func sendTextMessage(chatId: Int64, text: String, replyToId: Int64? = nil) {
        let clientMessageId = UUID().uuidString
        let tempId = UUID().uuidString
        
        let request = WebSocketSendMessageRequest(
            chatId: chatId,
            text: text,
            replyToId: replyToId,
            clientMessageId: clientMessageId,
            tempId: tempId
        )
        sendMessage(request)
    }
    
    func sendTypingStart(chatId: Int64) {
        sendMessage(WebSocketTypingStartRequest(chatId: chatId))
    }
    
    func sendTypingEnd(chatId: Int64) {
        sendMessage(WebSocketTypingEndRequest(chatId: chatId))
    }
    
    func markAsRead(messageId: Int64, chatId: Int64) {
        sendMessage(WebSocketReadReceiptRequest(messageId: messageId, chatId: chatId))
    }
    
    func deleteMessage(messageId: Int64, chatId: Int64) {
        sendMessage(WebSocketDeleteMessageRequest(messageId: messageId, chatId: chatId))
    }
    
    func confirmDelivery(deliveryId: String, messageId: Int64, chatId: Int64) {
        sendMessage(WebSocketDeliveryConfirmationRequest(
            delivery_id: deliveryId,
            messageId: messageId,
            chatId: chatId
        ))
    }
    
    // MARK: - Message Receiving
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue receiving
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.handleDisconnection()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleTextMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let type = json?["type"] as? String else { return }
            
            switch type {
            case "connected":
                handleConnected(data: data)
            case "error":
                handleError(data: data)
            case "ping":
                handlePing(data: data)
            case "chats":
                handleChats(data: data)
            case "messages":
                handleMessages(data: data)
            case "new_message":
                handleNewMessage(data: data)
            case "message_sent":
                handleMessageSent(data: data)
            case "typing_indicator":
                handleTypingIndicator(data: data, isTyping: true)
            case "typing_indicator_end":
                handleTypingIndicator(data: data, isTyping: false)
            case "message_read":
                handleMessageRead(data: data)
            case "message_deleted":
                handleMessageDeleted(data: data)
            case "unread_counts":
                handleUnreadCounts(data: data)
            case "user_status":
                // User status updates (online/offline) - can be ignored for now
                break
            case "delivery_confirmation_ack":
                // Delivery confirmation acknowledgment - can be ignored
                break
            case "read_receipt_response":
                // Read receipt response - can be ignored
                break
            default:
                print("⚠️ Unknown message type: \(type)")
            }
        } catch {
            print("❌ Error parsing message: \(error)")
        }
    }
    
    private func handleConnected(data: Data) {
        do {
            let response = try JSONDecoder().decode(WebSocketConnectedResponse.self, from: data)
            print("✅ WebSocket connected: \(response.message ?? "")")
            
            reconnectAttempts = 0
            
            Task { @MainActor in
                isConnected = true
                connectionError = nil
            }
            
            // Automatically request chats after connection to preload them
            getChats()
            
            // Note: Individual chat messages will be requested by ChatViewModel when needed
        } catch {
            print("❌ Error decoding connected response: \(error)")
        }
    }
    
    private func handleError(data: Data) {
        do {
            let response = try JSONDecoder().decode(WebSocketErrorResponse.self, from: data)
            print("❌ WebSocket error: \(response.message) (code: \(response.code ?? ""))")
            
            Task { @MainActor in
                connectionError = response.message
            }
            
            onError?(response.message, response.code)
            
            if response.code == "AUTH_FAILED" {
                Task { @MainActor in
                    isConnected = false
                }
                if response.reconnect == true {
                    reconnect()
                }
            }
        } catch {
            print("❌ Error decoding error response: \(error)")
        }
    }
    
    private func handlePing(data: Data) {
        do {
            let ping = try JSONDecoder().decode(WebSocketPingMessage.self, from: data)
            let pong = WebSocketPongMessage(
                type: "pong",
                timestamp: ping.timestamp,
                ping_id: ping.ping_id
            )
            sendMessage(pong)
        } catch {
            print("❌ Error handling ping: \(error)")
        }
    }
    
    private func handleChats(data: Data) {
        do {
            let response = try JSONDecoder().decode(WebSocketChatsResponse.self, from: data)
            print("✅ Decoded \(response.chats.count) chats from WebSocket")
            
            // Cache chats for immediate availability
            Task { @MainActor in
                self.cachedChats = response.chats
            }
            
            // Notify callback
            onChatsReceived?(response.chats)
        } catch {
            print("❌ Error decoding chats: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
            }
        }
    }
    
    private func handleMessages(data: Data) {
        do {
            let response = try JSONDecoder().decode(WebSocketMessagesResponse.self, from: data)
            onMessagesReceived?(response.chat_id, response.messages)
        } catch {
            print("❌ Error decoding messages: \(error)")
        }
    }
    
    private func handleNewMessage(data: Data) {
        do {
            let response = try JSONDecoder().decode(WebSocketNewMessageResponse.self, from: data)
            onNewMessage?(response.chatId, response.message)
            
            // Send delivery confirmation if required
            if response.requires_delivery_confirmation == true {
                let deliveryId = UUID().uuidString
                confirmDelivery(
                    deliveryId: deliveryId,
                    messageId: response.message.id,
                    chatId: response.chatId
                )
            }
        } catch {
            print("❌ Error decoding new message: \(error)")
        }
    }
    
    private func handleMessageSent(data: Data) {
        do {
            let response = try JSONDecoder().decode(WebSocketMessageSentResponse.self, from: data)
            onMessageSent?(response.chatId, response.messageId, response.clientMessageId)
        } catch {
            print("❌ Error decoding message sent: \(error)")
        }
    }
    
    private func handleTypingIndicator(data: Data, isTyping: Bool) {
        do {
            let response = try JSONDecoder().decode(WebSocketTypingIndicatorResponse.self, from: data)
            onTypingIndicator?(response.chatId, response.userId, response.username, isTyping)
        } catch {
            print("❌ Error decoding typing indicator: \(error)")
        }
    }
    
    private func handleMessageRead(data: Data) {
        // Parse message_read response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let chatId = json["chatId"] as? Int64,
           let messageId = json["messageId"] as? Int64 {
            onMessageRead?(chatId, messageId)
        }
    }
    
    private func handleMessageDeleted(data: Data) {
        // Parse message_deleted response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let chatId = json["chatId"] as? Int64,
           let messageId = json["messageId"] as? Int64 {
            onMessageDeleted?(chatId, messageId)
        }
    }
    
    private func handleUnreadCounts(data: Data) {
        do {
            let response = try JSONDecoder().decode(WebSocketUnreadCountsResponse.self, from: data)
            onUnreadCounts?(response.counts)
        } catch {
            print("❌ Error decoding unread counts: \(error)")
        }
    }
    
    private func handleDisconnection() {
        Task { @MainActor in
            isConnected = false
        }
        
        if shouldReconnect {
            reconnect()
        }
    }
    
    // MARK: - Ping Timer
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { _ in
            // Server sends ping, we just respond
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension MessengerWebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connection opened")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("⚠️ WebSocket connection closed: \(closeCode)")
        handleDisconnection()
    }
}

