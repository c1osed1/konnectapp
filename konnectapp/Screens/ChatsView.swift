//
//  ChatsView.swift
//  konnectapp
//
//  List of chats in iMessage/Telegram style
//

import SwiftUI

struct ChatsView: View {
    @StateObject private var viewModel = ChatsViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedChat: Chat?
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
    @ViewBuilder
    private var searchBarView: some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassSearchBar
            } else {
                fallbackSearchBar
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassSearchBar: some View {
        ZStack {
            Capsule()
                .fill(Color.clear)
                .glassEffect(in: Capsule())
            
            SearchBar(text: $viewModel.searchText)
                .frame(height: 44)
        }
        .frame(height: 44)
    }
    
    @ViewBuilder
    private var fallbackSearchBar: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.5))
            
            SearchBar(text: $viewModel.searchText)
                .frame(height: 44)
        }
        .frame(height: 44)
    }
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: AuthManager.shared.currentUser?.profile_background_url)
            
            VStack(spacing: 0) {
                // Search bar at the top
                searchBarView
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                
                if viewModel.isLoading && viewModel.chats.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(Color.appAccent)
                    Spacer()
                } else if viewModel.filteredChats.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: viewModel.searchText.isEmpty ? "message.fill" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(Color.themeTextSecondary)
                        
                        Text(viewModel.searchText.isEmpty ? "Нет чатов" : "Ничего не найдено")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.themeTextPrimary)
                        
                        Text(viewModel.searchText.isEmpty ? "Начните новую переписку" : "Попробуйте другой запрос")
                            .font(.system(size: 14))
                            .foregroundColor(Color.themeTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.filteredChats) { chat in
                                NavigationLink(value: chat) {
                                    ChatRowView(chat: chat)
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { _ in
                                // Hide keyboard when scrolling
                                hideKeyboard()
                            }
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // WebSocket should already be connected from MainView and chats should be preloaded
            // If chats are still empty, request them
            if viewModel.chats.isEmpty {
                if MessengerWebSocketService.shared.isConnected {
                    // Request chats immediately if WebSocket is connected
                    MessengerWebSocketService.shared.getChats()
                } else {
                    // Connect and request chats
                    viewModel.loadChats()
                }
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: chat.fullAvatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.themeBlockBackground)
                    .overlay(
                        Text(chat.title.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.appAccent)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(chat.title)
                        .font(.system(size: 17, weight: chat.unread_count > 0 ? .semibold : .regular))
                        .foregroundColor(Color.themeTextPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Time
                    if let lastMessage = chat.last_message {
                        Text(formatTime(lastMessage.created_at))
                            .font(.system(size: 15))
                            .foregroundColor(Color.themeTextSecondary)
                    }
                }
                
                HStack(alignment: .center, spacing: 8) {
                    if let lastMessage = chat.last_message {
                        Text(lastMessage.content)
                            .font(.system(size: 15))
                            .foregroundColor(chat.unread_count > 0 ? Color.themeTextPrimary : Color.themeTextSecondary)
                            .lineLimit(1)
                    } else {
                        Text("Нет сообщений")
                            .font(.system(size: 15))
                            .foregroundColor(Color.themeTextSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if chat.unread_count > 0 {
                        Text("\(chat.unread_count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, 6)
                            .background(Color.appAccent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Вчера"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return dateFormatter.string(from: date)
        }
    }
}

