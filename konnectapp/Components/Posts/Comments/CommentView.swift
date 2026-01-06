import SwiftUI

struct CommentView: View {
    let comment: Comment
    @Binding var navigationPath: NavigationPath
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    @State private var showReplies: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDeleting: Bool = false
    var onReply: ((Comment) -> Void)?
    var onReplyToReply: ((Reply, Int64) -> Void)?
    var onDelete: (() -> Void)?
    
    private var isMyComment: Bool {
        guard let currentUserId = authManager.currentUser?.id,
              let commentUserId = comment.user?.id else { return false }
        return commentUserId == currentUserId
    }
    
    init(comment: Comment, navigationPath: Binding<NavigationPath>, onReply: ((Comment) -> Void)? = nil, onReplyToReply: ((Reply, Int64) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.comment = comment
        self._navigationPath = navigationPath
        self.onReply = onReply
        self.onReplyToReply = onReplyToReply
        self.onDelete = onDelete
        _isLiked = State(initialValue: comment.user_liked ?? false)
        _likesCount = State(initialValue: comment.likes_count ?? 0)
        // Автоматически показываем replies, если они есть
        _showReplies = State(initialValue: (comment.replies != nil && !comment.replies!.isEmpty))
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Delete action background (left swipe - показываем справа)
            if isMyComment {
                HStack {
                    Spacer()
                    Button {
                        Task {
                            await deleteComment()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            Text("Удалить")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .opacity(dragOffset < 0 ? min(abs(dragOffset) / 100, 1.0) : 0)
            }
            
            // Reply action background (right swipe - показываем слева)
            HStack {
                Button {
                    onReply?(comment)
                } label: {
                    HStack {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        Text("Ответить")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
            .opacity(dragOffset > 0 ? min(dragOffset / 100, 1.0) : 0)
        
        // Comment content
        VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    if let user = comment.user {
                        Button {
                            navigationPath.append(user.username)
                        } label: {
                            AsyncImage(url: URL(string: user.avatar_url ?? (user.photo?.hasPrefix("http") == true ? user.photo! : "https://s3.k-connect.ru/static/uploads/avatar/\(user.id)/\(user.photo ?? "")"))) { phase in
                                switch phase {
                                case .empty:
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
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.black)
                                        )
                                        .frame(width: 40, height: 40)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                case .failure:
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
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.black)
                                        )
                                        .frame(width: 40, height: 40)
                                @unknown default:
                                    Circle()
                                        .fill(Color.themeBlockBackgroundSecondary)
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let user = comment.user {
                            HStack(spacing: 6) {
                                Button {
                                    navigationPath.append(user.username)
                                } label: {
                                    Text(user.name ?? user.username)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("@\(user.username)")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                
                                if let timestamp = comment.timestamp {
                                    Text(DateFormatterHelper.formatRelativeTime(timestamp))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.themeTextSecondary.opacity(0.8))
                                }
                            }
                        }
                        
                        if let content = comment.content, !content.isEmpty {
                            Text(content)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        if let image = comment.image, let imageURL = URL(string: image) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.themeBlockBackgroundSecondary)
                                        .frame(height: 200)
                                case .success(let img):
                                    img
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .failure:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.themeBlockBackgroundSecondary)
                                        .frame(height: 200)
                                @unknown default:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.themeBlockBackgroundSecondary)
                                        .frame(height: 200)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        HStack(spacing: 16) {
                            Button {
                                Task {
                                    await toggleLike()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 14))
                                        .foregroundColor(isLiked ? .red : Color.themeTextSecondary)
                                    
                                    if likesCount > 0 {
                                        Text("\(likesCount)")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.themeTextSecondary)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isLiking)
                            
                            if let repliesCount = comment.replies_count, repliesCount > 0 {
                                Button {
                                    showReplies.toggle()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrowshape.turn.up.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.themeTextSecondary)
                                        
                                        Text("\(repliesCount) ответ\(repliesCount == 1 ? "" : repliesCount < 5 ? "а" : "ов")")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.themeTextSecondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                if showReplies {
                    if let replies = comment.replies, !replies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(replies) { reply in
                                ReplyView(
                                    reply: reply,
                                    navigationPath: $navigationPath,
                                    onReply: {
                                        onReplyToReply?(reply, comment.id)
                                    }
                                )
                                .padding(.leading, 52)
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        // Если replies пустой, но replies_count > 0, возможно нужно загрузить
                        Text("Загрузка ответов...")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .padding(.leading, 52)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.1))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.themeBlockBackground.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        Color.appAccent.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            )
                            .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.1))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.themeBlockBackground.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        Color.appAccent.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            )
                    }
                }
            )
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        // Проверяем, что движение горизонтальное (не скролл)
                        let horizontalMovement = abs(value.translation.width)
                        let verticalMovement = abs(value.translation.height)
                        
                        // Свайп срабатывает только если горизонтальное движение больше вертикального
                        if horizontalMovement > verticalMovement {
                            if isMyComment {
                                // Allow both left and right swipe
                                dragOffset = value.translation.width
                            } else {
                                // Only right swipe for reply
                                dragOffset = max(value.translation.width, 0)
                            }
                        }
                    }
                    .onEnded { value in
                        let horizontalMovement = abs(value.translation.width)
                        let verticalMovement = abs(value.translation.height)
                        
                        // Проверяем, что это был горизонтальный свайп
                        if horizontalMovement > verticalMovement {
                            let threshold: CGFloat = 80
                            if abs(value.translation.width) > threshold {
                                if value.translation.width < -threshold && isMyComment {
                                    // Left swipe - delete
                                    Task {
                                        await deleteComment()
                                    }
                                } else if value.translation.width > threshold {
                                    // Right swipe - reply
                                    onReply?(comment)
                                }
                            }
                        }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .padding(.vertical, 2)
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

struct ReplyView: View {
    let reply: Reply
    @Binding var navigationPath: NavigationPath
    var onReply: (() -> Void)?
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    
    init(reply: Reply, navigationPath: Binding<NavigationPath>, onReply: (() -> Void)? = nil) {
        self.reply = reply
        self._navigationPath = navigationPath
        self.onReply = onReply
        _isLiked = State(initialValue: reply.user_liked ?? false)
        _likesCount = State(initialValue: reply.likes_count ?? 0)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let user = reply.user {
                Button {
                    navigationPath.append(user.username)
                } label: {
                    AsyncImage(url: URL(string: user.avatar_url ?? (user.photo?.hasPrefix("http") == true ? user.photo! : "https://s3.k-connect.ru/static/uploads/avatar/\(user.id)/\(user.photo ?? "")"))) { phase in
                        switch phase {
                        case .empty:
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
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                )
                                .frame(width: 32, height: 32)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure:
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
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                )
                                .frame(width: 32, height: 32)
                        @unknown default:
                            Circle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let user = reply.user {
                    HStack(spacing: 6) {
                        Button {
                            navigationPath.append(user.username)
                        } label: {
                            Text(user.name ?? user.username)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("@\(user.username)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        
                        if let timestamp = reply.timestamp {
                            Text(DateFormatterHelper.formatRelativeTime(timestamp))
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        }
                    }
                }
                
                if let content = reply.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let image = reply.image, let imageURL = URL(string: image) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(height: 150)
                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(height: 150)
                        @unknown default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(height: 150)
                        }
                    }
                    .padding(.top, 4)
                }
                
                HStack(spacing: 16) {
                    Button {
                        Task {
                            await toggleLike()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 13))
                                .foregroundColor(isLiked ? .red : Color(red: 0.6, green: 0.6, blue: 0.6))
                            
                            if likesCount > 0 {
                                Text("\(likesCount)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLiking)
                    
                    if let onReply = onReply {
                        Button {
                            onReply()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                Text("Ответить")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
