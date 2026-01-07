//
//  ChatView.swift
//  konnectapp
//
//  Chat screen in iMessage/Telegram style with all message types
//

import SwiftUI
import PhotosUI

struct ChatView: View {
    let chat: Chat
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var messageText: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var replyingToMessage: Message?
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollToMessageId: Int64?
    
    // No bottom padding - input area is separate and handles its own spacing
    private var bottomPadding: CGFloat {
        0
    }
    
    init(chat: Chat) {
        self.chat = chat
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chat.id))
    }
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: AuthManager.shared.currentUser?.profile_background_url)
            
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(Color.appAccent)
                                    .padding()
                            } else if viewModel.messages.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color.themeTextSecondary)
                                    
                                    Text("Нет сообщений")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Color.themeTextPrimary)
                                    
                                    Text("Начните переписку")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.themeTextSecondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                            } else {
                                // Load more indicator at top
                                if viewModel.isLoadingMore {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding()
                                        Spacer()
                                    }
                                }
                                
                                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                    let previousMessage = index > 0 ? viewModel.messages[index - 1] : nil
                                    let nextMessage = index < viewModel.messages.count - 1 ? viewModel.messages[index + 1] : nil
                                    
                                    // Determine spacing: smaller if messages are from same user
                                    let spacing: CGFloat = {
                                        if let previous = previousMessage, previous.sender_id == message.sender_id {
                                            // Same user - smaller spacing (close together)
                                            return 2
                                        }
                                        // Different user or first message - normal spacing
                                        return 12
                                    }()
                                    
                                    MessageBubbleView(
                                        chatId: chat.id,
                                        message: message,
                                        isOwnMessage: message.sender_id == AuthManager.shared.currentUser?.id,
                                        hasReplyToMyMessages: viewModel.hasReplyToMyMessages,
                                        isGroupChat: chat.is_group,
                                        previousMessage: previousMessage,
                                        nextMessage: nextMessage,
                                        chatMembers: chat.members ?? [],
                                        onReply: {
                                            replyingToMessage = message
                                        },
                                        onDelete: {
                                            viewModel.deleteMessage(messageId: message.id)
                                        }
                                    )
                                    .id(message.id)
                                    .padding(.top, spacing)
                                    .onAppear {
                                        // Load more messages when scrolling to the top
                                        if message.id == viewModel.messages.first?.id && viewModel.hasMoreMessages && !viewModel.isLoadingMore {
                                            // Store the first message ID to restore scroll position
                                            scrollToMessageId = message.id
                                            viewModel.loadMoreMessages(beforeId: message.id)
                                        }
                                    }
                                }
                                
                                // Typing indicator
                                if !viewModel.typingUsers.isEmpty {
                                    TypingIndicatorView(usernames: Array(viewModel.typingUsers.values))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, bottomPadding)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            // Hide keyboard when tapping on messages
                            isTextFieldFocused = false
                        }
                    )
                    .onChange(of: viewModel.messages.count) { oldValue, newValue in
                        if newValue > oldValue {
                            // Don't scroll if we're loading more (scrolling up)
                            if scrollToMessageId != nil {
                                // Skip auto-scroll when loading more messages
                                return
                            }
                            
                            // Scroll to bottom when new message is added (only if not loading more)
                            if let lastMessage = viewModel.messages.last, !viewModel.isLoadingMore {
                                // Use multiple attempts with increasing delays
                                let scrollToBottom = {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: scrollToBottom)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: scrollToBottom)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: scrollToBottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoadingMore) { oldValue, newValue in
                        // When loading more finishes, restore scroll position
                        if oldValue == true && newValue == false, let scrollToId = scrollToMessageId {
                            // Wait a bit longer for UI to update
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    proxy.scrollTo(scrollToId, anchor: .top)
                                }
                                // Clear after restoring
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    scrollToMessageId = nil
                                }
                            }
                        }
                    }
                    .onChange(of: messageText) { oldValue, newValue in
                        // Scroll to bottom when sending message (text cleared = message sent)
                        if !oldValue.isEmpty && newValue.isEmpty {
                            // Wait for message to be added and try multiple times
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: keyboardObserver.keyboardHeight) { oldValue, newValue in
                        // Scroll to bottom when keyboard appears
                        if newValue > oldValue, let lastMessage = viewModel.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Reply indicator
                if let replyingTo = replyingToMessage {
                    ReplyIndicatorView(message: replyingTo) {
                        replyingToMessage = nil
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // Input area
                MessageInputView(
                    text: $messageText,
                    selectedImageItem: $selectedImageItem,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: {
                        sendMessage()
                    },
                    onImageSelected: { image in
                        selectedImage = image
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .onTapGesture {
            // Hide keyboard when tapping outside
            isTextFieldFocused = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                chatTitleView
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                chatAvatarView
            }
        }
        .onAppear {
            viewModel.loadMessages()
        }
        .onChange(of: selectedImageItem) { oldValue, newValue in
            if let newValue = newValue {
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            sendPhoto(image: image)
                        }
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let textToSend = messageText
        messageText = ""
        replyingToMessage = nil
        // Don't hide keyboard - keep it open like in Telegram
        
        viewModel.sendMessage(text: textToSend, replyToId: replyingToMessage?.id)
    }
    
    private func sendPhoto(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let fileName = "\(Int(Date().timeIntervalSince1970))_photo.jpg"
        viewModel.sendPhoto(imageData: imageData, fileName: fileName, replyToId: replyingToMessage?.id)
        replyingToMessage = nil
        selectedImage = nil
        selectedImageItem = nil
    }
    
    // Get other user's avatar (not current user)
    private var otherUserAvatar: String? {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return chat.fullAvatarURL }
        
        // For personal chats, find the other member
        if !chat.is_group, let members = chat.members {
            if let otherMember = members.first(where: { $0.user_id != currentUserId }) {
                return otherMember.avatar
            }
        }
        
        // Fallback to chat avatar
        return chat.fullAvatarURL
    }
    
    @ViewBuilder
    private var chatTitleView: some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassTitle
            } else {
                fallbackTitle
            }
        }
    }
    
    @ViewBuilder
    private var chatAvatarView: some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassAvatar
            } else {
                fallbackAvatar
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassTitle: some View {
        Text(chat.title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.themeTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(in: Capsule())
    }
    
    @ViewBuilder
    private var fallbackTitle: some View {
        Text(chat.title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.themeTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.9))
            )
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
                .glassEffect(in: Circle())
            
            Group {
                if let avatarURL = URL(string: otherUserAvatar ?? "") {
                    CachedAsyncImage(url: avatarURL, cacheType: .avatar)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.themeBlockBackground)
                        .overlay(
                            Text(chat.title.prefix(1).uppercased())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.appAccent)
                        )
                        .frame(width: 40, height: 40)
                }
            }
        }
    }
    
    @ViewBuilder
    private var fallbackAvatar: some View {
        Group {
            if let avatarURL = URL(string: otherUserAvatar ?? "") {
                CachedAsyncImage(url: avatarURL, cacheType: .avatar)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.9))
                    )
            } else {
                Circle()
                    .fill(Color.themeBlockBackground)
                    .overlay(
                        Text(chat.title.prefix(1).uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.appAccent)
                    )
                    .frame(width: 40, height: 40)
            }
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let chatId: Int64
    let message: Message
    let isOwnMessage: Bool
    let hasReplyToMyMessages: Bool
    let isGroupChat: Bool
    let previousMessage: Message?
    let nextMessage: Message?
    let chatMembers: [ChatMember]
    let onReply: () -> Void
    let onDelete: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showImageFullscreen = false
    
    // Determine if we should show avatar and name (for group chats)
    private var shouldShowAvatarAndName: Bool {
        guard isGroupChat && !isOwnMessage else { return false }
        
        // Show if no previous message
        guard let previous = previousMessage else { return true }
        
        // Show if previous message is from different user
        if previous.sender_id != message.sender_id {
            return true
        }
        
        // Show if time difference is more than 5 minutes
        if let timeDiff = timeDifferenceInMinutes(previous.created_at, message.created_at), timeDiff > 5 {
            return true
        }
        
        return false
    }
    
    // Determine if we should show avatar (only for last message in a group)
    private var shouldShowAvatar: Bool {
        guard isGroupChat && !isOwnMessage else { return false }
        
        // Show avatar if this is the last message in a consecutive group
        // (next message is from different user, doesn't exist, or time difference > 5 minutes)
        if let next = nextMessage {
            // If next message is from different user, show avatar
            if next.sender_id != message.sender_id {
                return true
            }
            // If time difference > 5 minutes, show avatar
            if let timeDiff = timeDifferenceInMinutes(message.created_at, next.created_at), timeDiff > 5 {
                return true
            }
            // Otherwise, don't show (it's not the last in group)
            return false
        }
        // No next message - this is the last message, show avatar
        return true
    }
    
    // Get avatar URL for a user - prefer avatar_url from message, fallback to chat members
    private func getAvatarURL(for userId: Int64) -> String? {
        // First, try to use avatar_url from message (if available)
        if let avatarURL = message.avatar_url, !avatarURL.isEmpty {
            return avatarURL
        }
        
        // Fallback to chat members
        if let member = chatMembers.first(where: { $0.user_id == userId }) {
            return member.avatar
        }
        return nil
    }
    
    private func timeDifferenceInMinutes(_ date1: String, _ date2: String) -> Int? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date1Parsed: Date?
        var date2Parsed: Date?
        
        if let d1 = formatter.date(from: date1) {
            date1Parsed = d1
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            date1Parsed = formatter.date(from: date1)
        }
        
        if let d2 = formatter.date(from: date2) {
            date2Parsed = d2
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            date2Parsed = formatter.date(from: date2)
        }
        
        // Try custom format
        if date1Parsed == nil {
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            customFormatter.locale = Locale(identifier: "en_US_POSIX")
            customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            date1Parsed = customFormatter.date(from: date1)
        }
        
        if date2Parsed == nil {
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            customFormatter.locale = Locale(identifier: "en_US_POSIX")
            customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            date2Parsed = customFormatter.date(from: date2)
        }
        
        guard let d1 = date1Parsed, let d2 = date2Parsed else { return nil }
        return Int(abs(d2.timeIntervalSince(d1)) / 60)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar for group chats (left side, only for other users, only on last message in group)
            if shouldShowAvatar {
                // Get avatar URL from chat members
                let avatarURL = getAvatarURL(for: message.sender_id)
                Group {
                    if let url = URL(string: avatarURL ?? "") {
                        CachedAsyncImage(url: url, cacheType: .avatar)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent, Color(red: 0.75, green: 0.65, blue: 0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Text(message.sender_name.prefix(1).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .frame(width: 32, height: 32)
                    }
                }
            } else if isGroupChat && !isOwnMessage {
                // Spacer to align messages when avatar is not shown
                Spacer()
                    .frame(width: 32)
            }
            
            if isOwnMessage {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                // Sender name for group chats (only for other users, only in first message of group)
                if isGroupChat && !isOwnMessage && shouldShowAvatarAndName {
                    Text(message.sender_name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.appAccent)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                }
                
                // Reply indicator
                if message.reply_to_id != nil {
                    // Would need to fetch replied message, simplified for now
                }
                
                // Message content
                switch message.message_type {
                case "text":
                    HStack(alignment: .bottom, spacing: 6) {
                        Text(message.content)
                            .font(.system(size: 16))
                            .foregroundColor(isOwnMessage ? .white : Color.themeTextPrimary)
                        
                        // Time and read status inside bubble (Telegram style)
                        HStack(spacing: 4) {
                            Text(formatTime(message.created_at))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isOwnMessage ? .white.opacity(0.9) : Color.themeTextSecondary)
                            
                            if isOwnMessage {
                                // Check if message is read or if there's a reply to any of my messages (means they read it)
                                let isRead = (message.read_count ?? 0) > 0
                                
                                if isRead || hasReplyToMyMessages {
                                    // Two checkmarks for read messages (Telegram style) - overlapped
                                    ZStack(alignment: .leading) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                            .offset(x: 4)
                                    }
                                    .frame(width: 16, height: 12)
                                } else {
                                    // Single checkmark for sent messages
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                        .padding(.leading, 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isOwnMessage ? Color.appAccent : Color.themeBlockBackground)
                                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isOwnMessage ? Color.appAccent : Color.themeBlockBackground.opacity(0.9))
                            }
                        }
                    )
                    
                case "photo":
                    if let url = MessengerService.shared.getFileURL(chatId: chatId, filePath: message.content) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Sender name for group chats (only for other users, only in first message of group)
                            if isGroupChat && !isOwnMessage && shouldShowAvatarAndName {
                                Text(message.sender_name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.appAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 4)
                            }
                            
                            ZStack(alignment: .bottomTrailing) {
                                CachedAsyncImage(url: url, cacheType: .post)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: 250, maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .onTapGesture {
                                        showImageFullscreen = true
                                    }
                                
                                // Time overlay (Telegram style) - no read status for photos
                                HStack(spacing: 4) {
                                    Text(formatTime(message.created_at))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.black.opacity(0.4))
                                        .background(.ultraThinMaterial.opacity(0.4))
                                )
                                .padding(8)
                            }
                        }
                    }
                    
                case "video":
                    if let videoURL = message.fullVideoURL, let url = URL(string: videoURL) {
                        VideoMessageView(url: url)
                    } else if let url = MessengerService.shared.getFileURL(chatId: chatId, filePath: message.content) {
                        VideoMessageView(url: url)
                    }
                    
                case "audio":
                    if let audioURL = message.fullAudioURL, let url = URL(string: audioURL) {
                        AudioMessageView(url: url)
                    } else if let url = MessengerService.shared.getFileURL(chatId: chatId, filePath: message.content) {
                        AudioMessageView(url: url)
                    }
                    
                case "sticker":
                    if let stickerData = message.sticker_data {
                        StickerMessageView(stickerData: stickerData)
                    }
                    
                default:
                    HStack(alignment: .bottom, spacing: 6) {
                        Text(message.content)
                            .font(.system(size: 16))
                            .foregroundColor(isOwnMessage ? .white : Color.themeTextPrimary)
                        
                        // Time and read status inside bubble (Telegram style)
                        HStack(spacing: 4) {
                            Text(formatTime(message.created_at))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isOwnMessage ? .white.opacity(0.9) : Color.themeTextSecondary)
                            
                            if isOwnMessage {
                                // Check if message is read or if there's a reply to any of my messages (means they read it)
                                let isRead = (message.read_count ?? 0) > 0
                                
                                if isRead || hasReplyToMyMessages {
                                    // Two checkmarks for read messages (Telegram style) - overlapped
                                    ZStack(alignment: .leading) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                            .offset(x: 4)
                                    }
                                    .frame(width: 16, height: 12)
                                } else {
                                    // Single checkmark for sent messages
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                        .padding(.leading, 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isOwnMessage ? Color.appAccent : Color.themeBlockBackground)
                                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isOwnMessage ? Color.appAccent : Color.themeBlockBackground.opacity(0.9))
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isOwnMessage ? .trailing : .leading)
            .contextMenu {
                Button(action: onReply) {
                    Label("Ответить", systemImage: "arrowshape.turn.up.left")
                }
                
                if isOwnMessage {
                    Button(role: .destructive, action: onDelete) {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
            
            if !isOwnMessage {
                Spacer(minLength: 60)
            }
        }
        .sheet(isPresented: $showImageFullscreen) {
            if let photoURL = message.fullPhotoURL, let url = URL(string: photoURL) {
                FullScreenImageView(url: url)
            } else if let url = MessengerService.shared.getFileURL(chatId: chatId, filePath: message.content) {
                FullScreenImageView(url: url)
            }
        }
    }
}

// MARK: - Helper Functions

extension MessageBubbleView {
    func formatTime(_ dateString: String) -> String {
        var date: Date?
        
        // Try ISO8601 with fractional seconds first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsedDate = isoFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            // Try without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let parsedDate = isoFormatter.date(from: dateString) {
                date = parsedDate
            } else {
                // Try custom format: "2026-01-06 17:53:18Z"
                let customFormatter = DateFormatter()
                customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                customFormatter.locale = Locale(identifier: "en_US_POSIX")
                customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                date = customFormatter.date(from: dateString)
            }
        }
        
        guard let date = date else {
            return ""
        }
        
        // Telegram-style time format: always show HH:mm
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "ru_RU")
        return timeFormatter.string(from: date)
    }
}

// MARK: - Message Input View

struct MessageInputView: View {
    @Binding var text: String
    @Binding var selectedImageItem: PhotosPickerItem?
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    let onImageSelected: (UIImage) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        let appAccent = Color.appAccent
        let themeBlockBackground = Color.themeBlockBackground
        let isGlassEnabled = themeManager.isGlassEffectEnabled
        
        return HStack(spacing: 8) {
            // Photo picker button
            PhotosPicker(selection: $selectedImageItem, matching: .images) {
                Image(systemName: "paperclip")
                    .font(.system(size: 18))
                    .foregroundColor(appAccent)
                    .frame(width: 40, height: 40)
                    .background(
                        Group {
                            if #available(iOS 26.0, *) {
                                if isGlassEnabled {
                                    Capsule()
                                        .fill(themeBlockBackground)
                                        .glassEffect(.regularInteractive, in: Capsule())
                                } else {
                                    Capsule()
                                        .fill(themeBlockBackground.opacity(0.9))
                                }
                            } else {
                                Capsule()
                                    .fill(themeBlockBackground.opacity(0.9))
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Text field
            TextField("Сообщение", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(Color.themeTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .lineLimit(1...5)
                .focused($isTextFieldFocused)
                .background(
                    Group {
                        if #available(iOS 26.0, *) {
                            if isGlassEnabled {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(themeBlockBackground)
                                    .glassEffect(.regularInteractive, in: RoundedRectangle(cornerRadius: 20))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(themeBlockBackground.opacity(0.9))
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(themeBlockBackground.opacity(0.9))
                        }
                    }
                )
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Group {
                            if #available(iOS 26.0, *), isGlassEnabled {
                                Capsule()
                                    .fill(appAccent)
                                    .glassEffect(.regularInteractive, in: Capsule())
                            } else {
                                Capsule()
                                    .fill(appAccent)
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

// MARK: - Supporting Views

struct ReplyIndicatorView: View {
    let message: Message
    let onDismiss: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "arrowshape.turn.up.left")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appAccent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.sender_name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.appAccent)
                    
                    Text(message.content)
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Group {
                    if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeBlockBackground)
                            .glassEffect(.regularInteractive, in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    }
                }
            )
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.themeTextSecondary)
            }
        }
    }
}

struct TypingIndicatorView: View {
    let usernames: [String]
    
    var body: some View {
        HStack {
            Text("\(usernames.joined(separator: ", ")) печатает\(usernames.count > 1 ? "ут" : "")...")
                .font(.system(size: 14))
                .foregroundColor(Color.themeTextSecondary)
                .italic()
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct VideoMessageView: View {
    let url: URL
    
    var body: some View {
        // Simplified video view - would need AVPlayer for full implementation
        HStack {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
            
            Text("Видео")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.appAccent)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct AudioMessageView: View {
    let url: URL
    
    var body: some View {
        // Simplified audio view - would need AVAudioPlayer for full implementation
        HStack {
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text("Аудио")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.appAccent)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StickerMessageView: View {
    let stickerData: StickerData
    
    var body: some View {
        AsyncImage(url: URL(string: stickerData.fullURL)) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeBlockBackground)
                    .frame(width: 150, height: 150)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
            case .failure:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeBlockBackground)
                    .frame(width: 150, height: 150)
            @unknown default:
                EmptyView()
            }
        }
    }
}

struct FullScreenImageView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Text("Ошибка загрузки")
                        .foregroundColor(.white)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.themeTextPrimary)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

