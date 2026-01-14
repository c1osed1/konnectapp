import SwiftUI

struct PostCard: View {
    let post: Post
    @Binding var navigationPath: NavigationPath
    let hideEmptyCommentButton: Bool
    let forcePinnedStyle: Bool
    let pinnedAccentColor: Color?
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    @State private var toastMessage: String?
    @State private var showPostDetail: Bool = false
    @State private var updatedPoll: Poll?
    
    init(
        post: Post,
        navigationPath: Binding<NavigationPath>,
        hideEmptyCommentButton: Bool = false,
        forcePinnedStyle: Bool = false,
        pinnedAccentColor: Color? = nil
    ) {
        self.post = post
        self._navigationPath = navigationPath
        self.hideEmptyCommentButton = hideEmptyCommentButton
        self.forcePinnedStyle = forcePinnedStyle
        self.pinnedAccentColor = pinnedAccentColor
        _isLiked = State(initialValue: post.is_liked ?? false)
        _likesCount = State(initialValue: post.likes_count ?? 0)
    }

    private var isPinnedStyle: Bool {
        forcePinnedStyle || (post.is_pinned ?? false)
    }
    
    private var uniqueMedia: [String] {
        var allMedia: [String] = []
        if let media = post.media {
            allMedia.append(contentsOf: media)
        }
        if let images = post.images {
            allMedia.append(contentsOf: images)
        }
        if let image = post.image, !allMedia.contains(image) {
            allMedia.append(image)
        }
        return Array(Set(allMedia))
    }
    
    var body: some View {
        // Используем fallback версию для всех, чтобы иметь контроль над затемнением
        fallbackPostCard
            .layoutPriority(1)
        .onChange(of: toastMessage) { oldValue, newValue in
            if let message = newValue {
                ToastHelper.showToast(message: message)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    toastMessage = nil
                }
            }
        }
        .sheet(isPresented: $showPostDetail) {
            PostDetailView(post: post, navigationPath: $navigationPath)
        }
        // Если пост обновился извне (например, в модалке пришёл detailedPost),
        // синхронизируем локальные @State для лайков.
        .onChange(of: post.likes_count) { _, _ in
            syncLikeStateFromPost()
        }
        .onChange(of: post.is_liked) { _, _ in
            syncLikeStateFromPost()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PollVoteChanged"))) { notification in
            if let userInfo = notification.userInfo,
               let postId = userInfo["postId"] as? Int64,
               postId == post.id,
               let updatedPollData = userInfo["poll"] as? Poll {
                updatedPoll = updatedPollData
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassPostCard: some View {
            VStack(alignment: .leading, spacing: 0) {
                postContent
                postActions
            }
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var fallbackPostCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            postContent
            postActions
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Более темный фоновый слой
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.themeBlockBackground.opacity(0.95))
                
                // Блюр эффект с затемнением
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )

                if isPinnedStyle {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            (pinnedAccentColor ?? Color.appAccent).opacity(0.85),
                            lineWidth: 1.3
                        )
                }
            }
        )
        .clipped()
    }
    
    @ViewBuilder
    private var postContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    if post.type == "repost" || post.original_post != nil {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                    
                    if let user = post.user {
                        PostHeader(
                            user: user,
                            timestamp: post.created_at ?? post.timestamp,
                            navigationPath: $navigationPath,
                            isPinned: isPinnedStyle
                        )
                    }
                }
                
                if let content = post.content, !content.isEmpty {
                    PostTextContent(content: content, navigationPath: $navigationPath)
                        .onAppear {
                            // Логируем для отладки обрезки текста
                            if post.id == 11288 || content.count > 200 {
                                print("📝 PostCard id=\(post.id): content length=\(content.count), first 150 chars: \(content.prefix(150))")
                                if content.count > 200 {
                                    print("📝 PostCard id=\(post.id): last 100 chars: \(content.suffix(100))")
                                }
                            }
                        }
                }
            }
            .padding(16)
            
            if let originalPost = post.original_post {
                RepostedPostView(originalPost: originalPost, navigationPath: $navigationPath)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                // Показываем видео если есть
                if let videoURL = post.video {
                    PostVideoView(
                        videoURL: videoURL,
                        posterURL: post.video_poster,
                        isNsfw: post.is_nsfw ?? false
                    )
                }
                
                // Показываем изображения если есть
                if !uniqueMedia.isEmpty {
                    PostMediaView(mediaURLs: uniqueMedia, isNsfw: post.is_nsfw ?? false)
                }
                
                if let music = post.music, !music.isEmpty {
                    PostMusicView(tracks: music)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                }
                
                if let poll = updatedPoll ?? post.poll {
                    PollView(poll: poll, postId: post.id)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
        }
    }
    
    @ViewBuilder
    private var postActions: some View {
        HStack(spacing: 6) {
            PostLikeButton(
                isLiked: $isLiked,
                likesCount: $likesCount,
                isLiking: $isLiking,
                onToggle: toggleLike
            )
            
            PostCommentBlock(
                lastComment: post.last_comment,
                onTap: {
                    showPostDetail = true
                },
                isCommentsOpen: showPostDetail,
                hideEmptyCommentButton: hideEmptyCommentButton
            )
            
            PostMoreButton(post: post, toastMessage: $toastMessage)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
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
            let response = try await LikeService.shared.toggleLike(postId: Int(post.id))
            await MainActor.run {
                isLiked = response.liked
                likesCount = response.likesCount
            }
        } catch {
            await MainActor.run {
                isLiked = previousLiked
                likesCount = previousCount
            }
            print("❌ Like error: \(error.localizedDescription)")
        }
    }

    private func syncLikeStateFromPost() {
        guard !isLiking else { return }
        // Если поля отсутствуют в модели — не затираем текущий UI.
        if let liked = post.is_liked {
            isLiked = liked
        }
        if let cnt = post.likes_count {
            likesCount = cnt
        }
    }
}