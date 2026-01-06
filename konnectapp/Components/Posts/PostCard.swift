import SwiftUI

struct PostCard: View {
    let post: Post
    @Binding var navigationPath: NavigationPath
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    @State private var toastMessage: String?
    @State private var showPostDetail: Bool = false
    
    init(post: Post, navigationPath: Binding<NavigationPath>) {
        self.post = post
        self._navigationPath = navigationPath
        _isLiked = State(initialValue: post.is_liked ?? false)
        _likesCount = State(initialValue: post.likes_count ?? 0)
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
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassPostCard
            } else {
                fallbackPostCard
            }
        }
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
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
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
                            navigationPath: $navigationPath
                        )
                    }
                }
                
                if let content = post.content, !content.isEmpty {
                    PostTextContent(content: content)
                }
            }
            .padding(16)
            
            if let originalPost = post.original_post {
                RepostedPostView(originalPost: originalPost, navigationPath: $navigationPath)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                if !uniqueMedia.isEmpty {
                    PostMediaView(mediaURLs: uniqueMedia, isNsfw: post.is_nsfw ?? false)
                }
                
                if let music = post.music, !music.isEmpty {
                    PostMusicView(tracks: music)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
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
            
            PostCommentBlock(lastComment: post.last_comment) {
                showPostDetail = true
            }
            
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
}