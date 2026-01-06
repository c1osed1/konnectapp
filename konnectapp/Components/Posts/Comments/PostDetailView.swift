import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var detailedPost: Post?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var shouldRefreshComments: Bool = false
    @State private var replyingToComment: Comment?
    @State private var replyingToReply: Reply?
    @State private var replyingToReplyCommentId: Int64?
    
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
                            let displayPost: Post = {
                                if let detailedPost = detailedPost {
                                    // Если detailedPost не имеет original_post, но исходный post имеет, используем исходный
                                    if detailedPost.original_post == nil && post.original_post != nil {
                                        return post
                                    }
                                    return detailedPost
                                }
                                return post
                            }()
                            
                            if isLoading && detailedPost == nil {
                                ProgressView()
                                    .padding()
                            } else {
                                PostCard(post: displayPost, navigationPath: $navigationPath)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)
                            }
                            
                            CommentsListView(
                                postId: post.id,
                                navigationPath: $navigationPath,
                                shouldRefresh: Binding(
                                    get: { shouldRefreshComments },
                                    set: { shouldRefreshComments = $0 }
                                ),
                                replyingToComment: $replyingToComment,
                                replyingToReply: $replyingToReply,
                                replyingToReplyCommentId: $replyingToReplyCommentId
                            )
                            .frame(minHeight: 400)
                            .padding(.bottom, 80)
                        }
                    }
                    
                    CreateCommentView(
                        postId: post.id,
                        navigationPath: $navigationPath,
                        replyingToComment: $replyingToComment,
                        replyingToReply: $replyingToReply,
                        replyingToReplyCommentId: $replyingToReplyCommentId,
                        onCommentCreated: {
                            shouldRefreshComments.toggle()
                            replyingToComment = nil
                            replyingToReply = nil
                            replyingToReplyCommentId = nil
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

