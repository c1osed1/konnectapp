import SwiftUI

struct NotificationsModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var notificationChecker = NotificationChecker.shared
    @State private var notifications: [Notification] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showPostDetail: Post?
    @State private var allRead: Bool = false
    @State private var isMarkingAsRead: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackgroundStart,
                        Color.themeBackgroundEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading && notifications.isEmpty {
                    ProgressView()
                        .tint(Color.themeTextPrimary)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(Color.themeTextPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button("Повторить") {
                            Task {
                                await loadNotifications()
                            }
                        }
                        .foregroundColor(Color.themeTextPrimary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appAccent)
                        )
                    }
                } else if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(Color.themeTextSecondary)
                        Text("Нет уведомлений")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.themeTextPrimary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notifications) { notification in
                                NotificationRow(notification: notification) {
                                    handleNotificationTap(notification)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Уведомления")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !notifications.isEmpty && allRead {
                        Button {
                            Task {
                                await deleteAllNotifications()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(Color.themeTextPrimary)
                        }
                    } else if !notifications.isEmpty && !allRead {
                        Button {
                            Task {
                                await markAllAsRead()
                            }
                        } label: {
                            if isMarkingAsRead {
                                ProgressView()
                                    .tint(Color.themeTextPrimary)
                            } else {
                                Text("Прочитать все")
                                    .foregroundColor(Color.themeTextPrimary)
                            }
                        }
                        .disabled(isMarkingAsRead)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        // Обновляем счетчик при закрытии модалки
                        Task {
                            do {
                                let response = try await NotificationService.shared.getNotifications()
                                await MainActor.run {
                                    notificationChecker.unreadCount = response.unread_count ?? 0
                                }
                            } catch {
                                print("❌ Error loading unread count on dismiss: \(error)")
                            }
                        }
                        dismiss()
                    }
                    .foregroundColor(Color.themeTextPrimary)
                }
            }
        }
        .task {
            await loadNotifications()
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await NotificationService.shared.getNotifications()
            await MainActor.run {
                notifications = response.notifications
                // Проверяем, все ли уведомления прочитаны
                allRead = notifications.allSatisfy { $0.is_read == true }
                // Не обновляем счетчик здесь, чтобы не вызвать перерисовку родительского view
                // Счетчик будет обновлен при закрытии модалки
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func markAllAsRead() async {
        guard !isMarkingAsRead else { return }
        
        isMarkingAsRead = true
        defer { isMarkingAsRead = false }
        
        do {
            _ = try await NotificationService.shared.markAllAsRead()
            
            // Перезагружаем уведомления, чтобы получить актуальное состояние с сервера
            let response = try await NotificationService.shared.getNotifications()
            await MainActor.run {
                notifications = response.notifications
                allRead = notifications.allSatisfy { $0.is_read == true }
                // Обновляем счетчик только после обновления уведомлений, но не вызываем перерисовку родительского view
                // Обновим счетчик при закрытии модалки
            }
            print("✅ All notifications marked as read")
        } catch {
            await MainActor.run {
                errorMessage = "Ошибка при пометке как прочитанные: \(error.localizedDescription)"
            }
            print("❌ Error marking notifications as read: \(error)")
        }
    }
    
    private func deleteAllNotifications() async {
        do {
            let response = try await NotificationService.shared.deleteAllNotifications()
            await MainActor.run {
                notifications = []
                notificationChecker.unreadCount = 0
            }
            print("✅ All notifications deleted: \(response.message ?? "")")
        } catch {
            await MainActor.run {
                errorMessage = "Ошибка при удалении: \(error.localizedDescription)"
            }
            print("❌ Error deleting notifications: \(error)")
        }
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        guard let link = notification.link else { return }
        
        if link.hasPrefix("/post/") {
            let components = link.components(separatedBy: "/")
            if components.count >= 3, let postId = Int64(components[2].components(separatedBy: "?").first ?? "") {
                Task {
                    do {
                        let response = try await CommentService.shared.getPostDetail(postId: postId, includeComments: false)
                        if response.post != nil {
                            await MainActor.run {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    deepLinkHandler.targetPostId = postId
                                }
                            }
                        }
                    } catch {
                        print("❌ Error loading post from notification: \(error)")
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
            if let sender = notification.sender_user {
                CachedAsyncImage(url: URL(string: sender.avatar_url ?? ""), cacheType: .avatar)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.themeBlockBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: notificationIcon)
                            .foregroundColor(Color.themeTextSecondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notificationMessage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.themeTextPrimary)
                    .lineLimit(2)
                
                if let createdAt = notification.created_at {
                    Text(formatDate(createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextSecondary)
                }
            }
            
            Spacer()
            
            if notification.is_read == false {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeBlockBackground)
        )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case "post_like": return "heart.fill"
        case "comment": return "bubble.right.fill"
        case "reply": return "arrowshape.turn.up.left.fill"
        case "comment_like": return "heart.fill"
        case "reply_like": return "heart.fill"
        default: return "bell.fill"
        }
    }
    
    private var notificationMessage: String {
        guard let sender = notification.sender_user else {
            print("⚠️ NotificationRow: sender_user is nil for notification \(notification.id), message: '\(notification.message)'")
            return notification.message
        }
        
        let senderName: String
        if let name = sender.name, !name.isEmpty {
            senderName = name
            print("✅ NotificationRow: Using name '\(name)' for notification \(notification.id)")
        } else {
            senderName = sender.username
            print("⚠️ NotificationRow: name is nil or empty, using username '\(sender.username)' for notification \(notification.id)")
        }
        
        let result = "\(senderName) \(notification.message)"
        print("📝 NotificationRow: Final message for notification \(notification.id): '\(result)'")
        return result
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let diff = now.timeIntervalSince(date)
            if diff < 60 {
                return "только что"
            } else if diff < 3600 {
                let minutes = Int(diff / 60)
                return "\(minutes) мин назад"
            } else {
                let hours = Int(diff / 3600)
                return "\(hours) ч назад"
            }
        } else if calendar.isDateInYesterday(date) {
            return "вчера"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM"
            dateFormatter.locale = Locale(identifier: "ru_RU")
            return dateFormatter.string(from: date)
        }
    }
}

