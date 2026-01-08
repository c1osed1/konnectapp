import SwiftUI

// MARK: - Comment Content View (только комментарий, без replies)
struct CommentContentView: View {
    let comment: Comment
    @Binding var navigationPath: NavigationPath
    @StateObject private var authManager = AuthManager.shared
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    @State private var isDeleting: Bool = false
    @Binding var showReplies: Bool
    var onReply: ((Comment) -> Void)?
    var onDelete: (() -> Void)?
    
    private var isMyComment: Bool {
        guard let currentUserId = authManager.currentUser?.id,
              let commentUserId = comment.user?.id else { return false }
        return commentUserId == currentUserId
    }
    
    init(comment: Comment, navigationPath: Binding<NavigationPath>, showReplies: Binding<Bool>, onReply: ((Comment) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.comment = comment
        self._navigationPath = navigationPath
        self._showReplies = showReplies
        self.onReply = onReply
        self.onDelete = onDelete
        _isLiked = State(initialValue: comment.user_liked ?? false)
        _likesCount = State(initialValue: comment.likes_count ?? 0)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let user = comment.user {
                Button {
                    navigationPath.append(user.username)
                } label: {
                    Group {
                        let avatarURLString = user.avatar_url ?? (user.photo?.hasPrefix("http") == true ? user.photo! : "https://s3.k-connect.ru/static/uploads/avatar/\(user.id)/\(user.photo ?? "")")
                        if let avatarURL = URL(string: avatarURLString) {
                            CachedAsyncImage(url: avatarURL, cacheType: .avatar)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appAccent,
                                            Color(red: 0.75, green: 0.65, blue: 0.95)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Text(String((user.name ?? user.username).prefix(1)))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                )
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 3) {
                if let user = comment.user {
                    HStack(spacing: 4) {
                        Button {
                            navigationPath.append(user.username)
                        } label: {
                            Text(user.name ?? user.username)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.themeTextPrimary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("@\(user.username)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.themeTextSecondary)
                        
                        if let timestamp = comment.timestamp {
                            Text(DateFormatterHelper.formatRelativeTime(timestamp))
                                .font(.system(size: 10))
                                .foregroundColor(Color.themeTextSecondary.opacity(0.8))
                        }
                    }
                }
                
                if let content = comment.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 13))
                        .foregroundColor(Color.themeTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let image = comment.image, let imageURL = URL(string: image) {
                    CachedAsyncImage(url: imageURL, cacheType: .post)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 3)
                }
                
                HStack(spacing: 12) {
                    Button {
                        onReply?(comment)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 12))
                                .foregroundColor(Color.themeTextSecondary)
                            Text("Ответить")
                                .font(.system(size: 11))
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let repliesCount = comment.replies_count, repliesCount > 0 {
                        Button {
                            showReplies.toggle()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.themeTextSecondary)
                                
                                Text("\(repliesCount)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.themeTextSecondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await toggleLike()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor(isLiked ? .red : Color.themeTextSecondary)
                            
                            if likesCount > 0 {
                                Text("\(likesCount)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.themeTextSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLiking)
                }
                .padding(.top, 3)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        )
        .contextMenu {
            if let username = comment.user?.username {
                Button {
                    onReply?(comment)
                } label: {
                    Label("Ответить @\(username)", systemImage: "arrowshape.turn.up.left")
                }
            } else {
                Button {
                    onReply?(comment)
                } label: {
                    Label("Ответить", systemImage: "arrowshape.turn.up.left")
                }
            }
            
            if isMyComment {
                Button(role: .destructive) {
                    Task {
                        await deleteComment()
                    }
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            }
        }
    }
    
    private func toggleLike() async {
        guard !isLiking else { return }
        
        isLiking = true
        defer { isLiking = false }
        
        let previousLiked = isLiked
        let previousCount = likesCount
        
        isLiked.toggle()
        if isLiked {
            likesCount += 1
        } else {
            likesCount = max(0, likesCount - 1)
        }
        
        do {
            let response = try await CommentService.shared.likeComment(commentId: comment.id)
            await MainActor.run {
                isLiked = response.liked
                likesCount = response.likesCount
            }
        } catch {
            await MainActor.run {
                isLiked = previousLiked
                likesCount = previousCount
            }
            print("❌ Comment like error: \(error.localizedDescription)")
        }
    }
    
    private func deleteComment() async {
        guard !isDeleting else { return }
        isDeleting = true
        
        do {
            try await CommentService.shared.deleteComment(commentId: comment.id)
            await MainActor.run {
                onDelete?()
            }
        } catch {
            await MainActor.run {
                ToastHelper.showToast(message: "Ошибка удаления: \(error.localizedDescription)")
            }
            print("❌ Delete comment error: \(error.localizedDescription)")
        }
        
        isDeleting = false
    }
}

// MARK: - Comment View (обертка с комментарием и replies)
struct CommentView: View {
    let comment: Comment
    @Binding var navigationPath: NavigationPath
    @State private var showReplies: Bool = false
    @State private var currentReplies: [Reply]?
    var onReply: ((Comment) -> Void)?
    var onReplyToReply: ((Reply, Int64) -> Void)?
    var onDelete: (() -> Void)?
    
    init(comment: Comment, navigationPath: Binding<NavigationPath>, onReply: ((Comment) -> Void)? = nil, onReplyToReply: ((Reply, Int64) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.comment = comment
        self._navigationPath = navigationPath
        self.onReply = onReply
        self.onReplyToReply = onReplyToReply
        self.onDelete = onDelete
        // Автоматически показываем replies, если они есть
        _showReplies = State(initialValue: (comment.replies != nil && !comment.replies!.isEmpty))
        _currentReplies = State(initialValue: comment.replies)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Комментарий - отдельный компонент, изолированный
            CommentContentView(
                comment: comment,
                navigationPath: $navigationPath,
                showReplies: $showReplies,
                onReply: onReply,
                onDelete: onDelete
            )
            .id("comment-\(comment.id)") // Уникальный ID для изоляции
            
            // Replies - полностью отдельная область, не наследует contextMenu
            // Используем отдельный контейнер с явной изоляцией
            repliesSection
            .id("replies-\(comment.id)") // Уникальный ID для изоляции
        }
        .padding(.vertical, 1)
    }
    
    @ViewBuilder
    private var repliesSection: some View {
        if showReplies {
            if let replies = currentReplies, !replies.isEmpty {
                // Обертываем в отдельный контейнер для полной изоляции
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(replies) { reply in
                        ReplyView(
                            reply: reply,
                            navigationPath: $navigationPath,
                            onReply: {
                                onReplyToReply?(reply, comment.id)
                            },
                            onDelete: {
                                currentReplies?.removeAll { $0.id == reply.id }
                                if currentReplies?.isEmpty == true {
                                    showReplies = false
                                }
                            }
                        )
                        .padding(.leading, 40)
                    }
                }
                .padding(.top, 6)
                .background(Color.clear)
                .contentShape(Rectangle())
                .allowsHitTesting(true)
            } else {
                // Если replies пустой, но replies_count > 0, возможно нужно загрузить
                Text("Загрузка ответов...")
                    .font(.system(size: 11))
                    .foregroundColor(Color.themeTextSecondary)
                    .padding(.leading, 40)
                    .padding(.top, 6)
            }
        }
    }
}

struct ReplyView: View {
    let reply: Reply
    @Binding var navigationPath: NavigationPath
    var onReply: (() -> Void)?
    @StateObject private var authManager = AuthManager.shared
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    @State private var isDeleting: Bool = false
    var onDelete: (() -> Void)?
    
    private var isMyReply: Bool {
        guard let currentUserId = authManager.currentUser?.id,
              let replyUserId = reply.user?.id else { return false }
        return replyUserId == currentUserId
    }
    
    init(reply: Reply, navigationPath: Binding<NavigationPath>, onReply: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.reply = reply
        self._navigationPath = navigationPath
        self.onReply = onReply
        self.onDelete = onDelete
        _isLiked = State(initialValue: reply.user_liked ?? false)
        _likesCount = State(initialValue: reply.likes_count ?? 0)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let user = reply.user {
                Button {
                    navigationPath.append(user.username)
                } label: {
                    Group {
                        let avatarURLString = user.avatar_url ?? (user.photo?.hasPrefix("http") == true ? user.photo! : "https://s3.k-connect.ru/static/uploads/avatar/\(user.id)/\(user.photo ?? "")")
                        if let avatarURL = URL(string: avatarURLString) {
                            CachedAsyncImage(url: avatarURL, cacheType: .avatar)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appAccent,
                                            Color(red: 0.75, green: 0.65, blue: 0.95)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Text(String((user.name ?? user.username).prefix(1)))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                )
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 3) {
                if let user = reply.user {
                    HStack(spacing: 4) {
                        Button {
                            navigationPath.append(user.username)
                        } label: {
                            Text(user.name ?? user.username)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.themeTextPrimary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("@\(user.username)")
                            .font(.system(size: 10))
                            .foregroundColor(Color.themeTextSecondary)
                        
                        if let timestamp = reply.timestamp {
                            Text(DateFormatterHelper.formatRelativeTime(timestamp))
                                .font(.system(size: 9))
                                .foregroundColor(Color.themeTextSecondary.opacity(0.8))
                        }
                    }
                }
                
                if let content = reply.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let image = reply.image, let imageURL = URL(string: image) {
                    CachedAsyncImage(url: imageURL, cacheType: .post)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 3)
                }
                
                HStack(spacing: 12) {
                    if let onReply = onReply {
                        Button {
                            onReply()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.themeTextSecondary)
                                Text("Ответить")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.themeTextSecondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await toggleLike()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 11))
                                .foregroundColor(isLiked ? .red : Color.themeTextSecondary)
                            
                            if likesCount > 0 {
                                Text("\(likesCount)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.themeTextSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLiking)
                }
                .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .contentShape(Rectangle())
        .contextMenu {
            if let onReply = onReply, let username = reply.user?.username {
                Button {
                    onReply()
                } label: {
                    Label("Ответить @\(username)", systemImage: "arrowshape.turn.up.left")
                }
            } else if let onReply = onReply {
                Button {
                    onReply()
                } label: {
                    Label("Ответить", systemImage: "arrowshape.turn.up.left")
                }
            }
            
            if isMyReply {
                Button(role: .destructive) {
                    Task {
                        await deleteReply()
                    }
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            }
        }
    }
    
    private func deleteReply() async {
        guard !isDeleting else { return }
        isDeleting = true
        
        do {
            try await CommentService.shared.deleteComment(commentId: reply.id)
            await MainActor.run {
                onDelete?()
            }
        } catch {
            await MainActor.run {
                ToastHelper.showToast(message: "Ошибка удаления: \(error.localizedDescription)")
            }
            print("❌ Delete reply error: \(error.localizedDescription)")
        }
        
        isDeleting = false
    }
    
    private func toggleLike() async {
        guard !isLiking else { return }
        
        isLiking = true
        defer { isLiking = false }
        
        let previousLiked = isLiked
        let previousCount = likesCount
        
        isLiked.toggle()
        if isLiked {
            likesCount += 1
        } else {
            likesCount = max(0, likesCount - 1)
        }
        
        do {
            let response = try await CommentService.shared.likeComment(commentId: reply.id)
            await MainActor.run {
                isLiked = response.liked
                likesCount = response.likesCount
            }
        } catch {
            await MainActor.run {
                isLiked = previousLiked
                likesCount = previousCount
            }
            print("❌ Reply like error: \(error.localizedDescription)")
        }
    }
}
