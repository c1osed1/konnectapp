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
    @State private var messageText: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var replyingToMessage: Message?
    @FocusState private var isTextFieldFocused: Bool
    
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
                        LazyVStack(spacing: 12) {
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
                                ForEach(viewModel.messages) { message in
                                    MessageBubbleView(
                                        chatId: chat.id,
                                        message: message,
                                        isOwnMessage: message.sender_id == AuthManager.shared.currentUser?.id,
                                        onReply: {
                                            replyingToMessage = message
                                        },
                                        onDelete: {
                                            viewModel.deleteMessage(messageId: message.id)
                                        }
                                    )
                                    .id(message.id)
                                }
                                
                                // Typing indicator
                                if !viewModel.typingUsers.isEmpty {
                                    TypingIndicatorView(usernames: Array(viewModel.typingUsers.values))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            // Hide keyboard when tapping on messages
                            isTextFieldFocused = false
                        }
                    )
                    .onChange(of: viewModel.messages.count) { oldValue, newValue in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
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
        
        viewModel.sendMessage(text: messageText, replyToId: replyingToMessage?.id)
        messageText = ""
        replyingToMessage = nil
        isTextFieldFocused = false
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
            
            AsyncImage(url: URL(string: otherUserAvatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.themeBlockBackground)
                    .overlay(
                        Text(chat.title.prefix(1).uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.appAccent)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var fallbackAvatar: some View {
        AsyncImage(url: URL(string: otherUserAvatar ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.themeBlockBackground)
                .overlay(
                    Text(chat.title.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appAccent)
                )
        }
        .frame(width: 40, height: 40)
        .background(
            Circle()
                .fill(.ultraThinMaterial.opacity(0.9))
        )
        .clipShape(Circle())
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let chatId: Int64
    let message: Message
    let isOwnMessage: Bool
    let onReply: () -> Void
    let onDelete: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showImageFullscreen = false
    
    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
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
                        
                        // Time and read status inside bubble
                        HStack(spacing: 3) {
                            Text(formatTime(message.created_at))
                                .font(.system(size: 12))
                                .foregroundColor(isOwnMessage ? .white.opacity(0.8) : Color.themeTextSecondary)
                            
                            if isOwnMessage {
                                if let isRead = message.is_read, isRead > 0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                } else {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
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
                        ZStack(alignment: .bottomTrailing) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.themeBlockBackground)
                                        .frame(width: 200, height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: 250, maxHeight: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .onTapGesture {
                                            showImageFullscreen = true
                                        }
                                case .failure:
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.themeBlockBackground)
                                        .frame(width: 200, height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                            // Time and read status overlay
                            HStack(spacing: 3) {
                                Text(formatTime(message.created_at))
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                
                                if isOwnMessage {
                                    if let isRead = message.is_read, isRead > 0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    } else {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black.opacity(0.3))
                                    .background(.ultraThinMaterial.opacity(0.3))
                            )
                            .padding(8)
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
                        
                        // Time and read status inside bubble
                        HStack(spacing: 3) {
                            Text(formatTime(message.created_at))
                                .font(.system(size: 12))
                                .foregroundColor(isOwnMessage ? .white.opacity(0.8) : Color.themeTextSecondary)
                            
                            if isOwnMessage {
                                if let isRead = message.is_read, isRead > 0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                } else {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
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
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
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
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

