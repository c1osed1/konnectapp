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
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            currentPage = 1
            posts = []
            errorMessage = nil
        }
        
        do {
            let response = try await FeedService.shared.getFeed(
                page: 1,
                perPage: 20,
                sort: feedType,
                includeAll: feedType == .all
            )
            
            await MainActor.run {
                self.posts = response.posts
                self.hasMore = response.has_next
                self.currentPage = 2
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
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
}

