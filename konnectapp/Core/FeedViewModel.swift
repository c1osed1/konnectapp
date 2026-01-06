import Foundation
import Combine

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var currentPage = 1
    @Published var feedType: FeedType = .all
    @Published var errorMessage: String?
    
    private var loadingMore = false
    
    func loadInitialFeed() async {
        // Разрешаем повторные вызовы для pull-to-refresh
        // Но используем флаг, чтобы не запускать несколько запросов одновременно
        let shouldLoad = await MainActor.run {
            if isLoading {
                return false
            }
            isLoading = true
            currentPage = 1
            errorMessage = nil
            return true
        }
        
        guard shouldLoad else { return }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            print("📥 Loading feed: type=\(feedType.rawValue), page=1")
            let response = try await FeedService.shared.getFeed(
                page: 1,
                perPage: 20,
                sort: feedType,
                includeAll: feedType == .all
            )
            
            print("✅ Feed loaded: \(response.posts.count) posts")
            
            await MainActor.run {
                self.posts = response.posts
                self.hasMore = response.has_next
                self.currentPage = 2
                self.errorMessage = nil
            }
        } catch {
            let nsError = error as NSError
            // Игнорируем ошибки отмены (cancellation) - это нормально при pull-to-refresh
            if error is CancellationError || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                print("ℹ️ Feed loading cancelled (normal for pull-to-refresh)")
                return
            }
            
            print("❌ Feed loading error: \(error.localizedDescription)")
            await MainActor.run {
                if let authError = error as? AuthError {
                    self.errorMessage = authError.errorDescription
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadMorePosts() async {
        guard !loadingMore && hasMore && !isLoading else { return }
        
        loadingMore = true
        
        do {
            let response = try await FeedService.shared.getFeed(
                page: currentPage,
                perPage: 10,
                sort: feedType,
                includeAll: feedType == .all
            )
            
            await MainActor.run {
                let existingIds = Set(self.posts.map { $0.id })
                let newPosts = response.posts.filter { !existingIds.contains($0.id) }
                self.posts.append(contentsOf: newPosts)
                self.hasMore = response.has_next
                self.currentPage += 1
                self.loadingMore = false
            }
        } catch {
            await MainActor.run {
                self.hasMore = false
                self.loadingMore = false
            }
        }
    }
    
    func changeFeedType(_ type: FeedType) async {
        feedType = type
        await loadInitialFeed()
    }
    
    func addPostToFeed(_ post: Post) {
        Task { @MainActor in
            // Добавляем пост в начало списка, если его еще нет
            if !posts.contains(where: { $0.id == post.id }) {
                posts.insert(post, at: 0)
            }
        }
    }
    
    func removePost(postId: Int64) {
        Task { @MainActor in
            posts.removeAll { $0.id == postId }
        }
    }
}

