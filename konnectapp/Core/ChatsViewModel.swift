//
//  ChatsViewModel.swift
//  konnectapp
//
//  ViewModel for managing the list of chats
//

import Foundation
import Combine

class ChatsViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var filteredChats: [Chat] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let webSocketService = MessengerWebSocketService.shared
    private let messengerService = MessengerService.shared
    
    init() {
        setupWebSocketCallbacks()
        
        // Load cached chats immediately if available
        if !webSocketService.cachedChats.isEmpty {
            self.chats = webSocketService.cachedChats.sorted { $0.updated_at > $1.updated_at }
            self.updateFilteredChats()
            print("✅ Loaded \(self.chats.count) cached chats from WebSocketService")
        }
        
        // Observe search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredChats()
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredChats() {
        if searchText.isEmpty {
            filteredChats = chats
        } else {
            filteredChats = chats.filter { chat in
                chat.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func loadChats() {
        // Don't reload if already loading or if we have chats
        guard !isLoading else { return }
        
        Task {
            await MainActor.run {
                isLoading = true
                error = nil
            }
            
            // Connect to WebSocket and request chats directly
            if webSocketService.isConnected {
                // WebSocket is already connected, request chats immediately
                webSocketService.getChats()
                // Keep isLoading = true until WebSocket responds via callback
            } else {
                // WebSocket not connected, connect first
                // Keep isLoading = true until WebSocket connects and loads chats
                webSocketService.connect()
                // WebSocket will automatically request chats after connection
            }
        }
    }
    
    private func setupWebSocketCallbacks() {
        webSocketService.onChatsReceived = { [weak self] chats in
            Task { @MainActor in
                guard let self = self else { return }
                self.chats = chats.sorted { $0.updated_at > $1.updated_at }
                self.updateFilteredChats()
                self.isLoading = false
                self.error = nil // Clear any previous errors
                print("✅ Updated UI with \(chats.count) chats from WebSocket")
            }
        }
        
        webSocketService.onNewMessage = { [weak self] chatId, message in
            Task { @MainActor in
                if let index = self?.chats.firstIndex(where: { $0.id == chatId }) {
                    let updatedChat = self!.chats[index]
                    // Формируем content для last_message
                    let lastMessageContent: String
                    if message.message_type == "photo" || message.message_type == "video" || message.message_type == "audio" {
                        lastMessageContent = "[Вложение]"
                    } else {
                        lastMessageContent = message.content
                    }
                    let lastMessage = LastMessage(
                        id: message.id,
                        sender_id: message.sender_id,
                        message_type: message.message_type,
                        content: lastMessageContent,
                        created_at: message.created_at,
                        is_read: message.is_read
                    )
                    // Create updated chat with new last message
                    let newChat = Chat(
                        id: updatedChat.id,
                        title: updatedChat.title,
                        chat_type: updatedChat.chat_type,
                        is_group: updatedChat.is_group,
                        avatar: updatedChat.avatar,
                        created_at: updatedChat.created_at,
                        updated_at: message.created_at,
                        is_encrypted: updatedChat.is_encrypted,
                        last_message: lastMessage,
                        unread_count: updatedChat.unread_count + (message.sender_id != AuthManager.shared.currentUser?.id ? 1 : 0),
                        members: updatedChat.members
                    )
                    self!.chats[index] = newChat
                    self!.chats.sort { $0.updated_at > $1.updated_at }
                }
            }
        }
        
        webSocketService.onUnreadCounts = { [weak self] counts in
            Task { @MainActor in
                for (chatIdString, count) in counts {
                    if let chatId = Int64(chatIdString),
                       let index = self?.chats.firstIndex(where: { $0.id == chatId }) {
                        let updatedChat = self!.chats[index]
                        let newChat = Chat(
                            id: updatedChat.id,
                            title: updatedChat.title,
                            chat_type: updatedChat.chat_type,
                            is_group: updatedChat.is_group,
                            avatar: updatedChat.avatar,
                            created_at: updatedChat.created_at,
                            updated_at: updatedChat.updated_at,
                            is_encrypted: updatedChat.is_encrypted,
                            last_message: updatedChat.last_message,
                            unread_count: count,
                            members: updatedChat.members
                        )
                        self!.chats[index] = newChat
                    }
                }
            }
        }
    }
    
    func connectWebSocket() {
        if !webSocketService.isConnected {
            webSocketService.connect()
        } else {
            // If already connected, request chats immediately
            webSocketService.getChats()
        }
    }
    
    func disconnectWebSocket() {
        // Don't disconnect, keep connection alive for real-time updates
    }
}

