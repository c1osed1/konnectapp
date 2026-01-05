import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var detailedPost: Post?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var shouldRefreshComments: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.06),
                        Color(red: 0.1, green: 0.1, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            if let detailedPost = detailedPost {
                                PostDetailContentView(post: detailedPost, navigationPath: $navigationPath)
                            } else if isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                PostDetailContentView(post: post, navigationPath: $navigationPath)
                            }
                            
                            CommentsListView(
                                postId: post.id,
                                navigationPath: $navigationPath,
                                shouldRefresh: Binding(
                                    get: { shouldRefreshComments },
                                    set: { shouldRefreshComments = $0 }
                                )
                            )
                            .frame(minHeight: 400)
                            .padding(.bottom, 80)
                        }
                    }
                    
                    CreateCommentView(
                        postId: post.id,
                        navigationPath: $navigationPath,
                        onCommentCreated: {
                            shouldRefreshComments.toggle()
                        }
                    )
                }
            }
            .navigationTitle("Пост")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await loadPostDetail()
        }
    }
    
    private func loadPostDetail() async {
        isLoading = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let response = try await CommentService.shared.getPostDetail(postId: post.id, includeComments: false)
            
            await MainActor.run {
                if let post = response.post {
                    detailedPost = post
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            print("❌ Load post detail error: \(error.localizedDescription)")
        }
    }
}

struct PostDetailContentView: View {
    let post: Post
    @Binding var navigationPath: NavigationPath
    
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
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                if let user = post.user {
                    PostHeader(
                        user: user,
                        timestamp: post.created_at ?? post.timestamp,
                        navigationPath: $navigationPath
                    )
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
            
            HStack(spacing: 16) {
                if let viewsCount = post.views_count {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(viewsCount)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                
                if let likesCount = post.likes_count {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(likesCount)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                
                if let commentsCount = post.comments_count {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(commentsCount)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                
                if let repostsCount = post.reposts_count {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(repostsCount)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                    lineWidth: 0.5
                                )
                        )
                }
            }
        )
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
}

