import SwiftUI

struct CommentsListView: View {
    let postId: Int64
    @Binding var navigationPath: NavigationPath
    @Binding var shouldRefresh: Bool
    @State private var comments: [Comment] = []
    @State private var isLoading: Bool = false
    @State private var currentPage: Int = 1
    @State private var hasNext: Bool = true
    @State private var errorMessage: String?
    
    init(postId: Int64, navigationPath: Binding<NavigationPath>, shouldRefresh: Binding<Bool>? = nil) {
        self.postId = postId
        self._navigationPath = navigationPath
        self._shouldRefresh = shouldRefresh ?? .constant(false)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if comments.isEmpty && isLoading {
                    ProgressView()
                        .padding()
                } else if comments.isEmpty && !isLoading {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        Text("Нет комментариев")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(comments) { comment in
                        CommentView(comment: comment, navigationPath: $navigationPath)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        Divider()
                            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .padding(.leading, 16)
                    }
                    
                    if hasNext {
                        Button {
                            Task {
                                await loadMoreComments()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                Text("Загрузить еще")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                                    .padding()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .refreshable {
            await loadComments(refresh: true)
        }
        .task {
            await loadComments()
        }
        .onChange(of: shouldRefresh) { oldValue, newValue in
            if newValue && !oldValue {
                Task {
                    await loadComments(refresh: true)
                    await MainActor.run {
                        shouldRefresh = false
                    }
                }
            }
        }
    }
    
    private func loadComments(refresh: Bool = false) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let page = refresh ? 1 : currentPage
            let response = try await CommentService.shared.getComments(postId: postId, page: page, limit: 20)
            
            await MainActor.run {
                if refresh {
                    comments = response.comments
                    currentPage = 1
                } else {
                    comments.append(contentsOf: response.comments)
                }
                
                hasNext = response.pagination?.has_next ?? false
                if hasNext {
                    currentPage += 1
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            print("❌ Load comments error: \(error.localizedDescription)")
        }
    }
    
    private func loadMoreComments() async {
        guard hasNext && !isLoading else { return }
        await loadComments()
    }
    
}

