import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: ProfileResponse?
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var hasMore: Bool = true
    @Published var currentPage: Int = 1
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadProfile(userIdentifier: String) async {
        print("🔵 ProfileViewModel: Starting to load profile for: \(userIdentifier)")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
                print("🟢 ProfileViewModel: Finished loading profile")
            }
        }
        
        do {
            print("🔵 ProfileViewModel: Calling ProfileService.getProfile...")
            let profileResponse = try await ProfileService.shared.getProfile(userIdentifier: userIdentifier)
            print("✅ ProfileViewModel: Successfully received profile response")
            await MainActor.run {
                self.profile = profileResponse
                print("✅ ProfileViewModel: Profile set in view model")
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("⚠️ ProfileViewModel: Request was cancelled, ignoring...")
                return
            }
            
            print("❌ ProfileViewModel: Error loading profile: \(error)")
            print("❌ ProfileViewModel: Error type: \(type(of: error))")
            if let decodingError = error as? DecodingError {
                print("❌ ProfileViewModel: DecodingError details: \(decodingError)")
            }
            await MainActor.run {
                errorMessage = error.localizedDescription
                print("❌ ProfileViewModel: Error message set: \(error.localizedDescription)")
            }
        }
    }
    
    func loadProfilePosts(userIdentifier: String, page: Int = 1) async {
        await MainActor.run {
            isLoadingPosts = true
        }
        
        defer {
            Task { @MainActor in
                isLoadingPosts = false
            }
        }
        
        do {
            let feedResponse = try await ProfileService.shared.getProfilePosts(
                userIdentifier: userIdentifier,
                page: page,
                perPage: 10
            )
            
            await MainActor.run {
                if page == 1 {
                    self.posts = feedResponse.posts
                } else {
                    let existingIds = Set(self.posts.map { $0.id })
                    let newPosts = feedResponse.posts.filter { !existingIds.contains($0.id) }
                    self.posts.append(contentsOf: newPosts)
                }
                self.hasMore = feedResponse.has_next
                self.currentPage = feedResponse.page
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleFollow() async {
        guard let currentProfile = profile else { return }
        
        do {
            let response = try await ProfileService.shared.followUser(followedId: currentProfile.user.id)
            await MainActor.run {
                let currentFollowersCount = currentProfile.followers_count ?? 0
                let newFollowersCount: Int
                if response.is_following {
                    newFollowersCount = currentFollowersCount + 1
                } else {
                    newFollowersCount = max(0, currentFollowersCount - 1)
                }
                
                self.profile = ProfileResponse(
                    user: currentProfile.user,
                    is_following: response.is_following,
                    is_friend: currentProfile.is_friend,
                    notifications_enabled: currentProfile.notifications_enabled,
                    socials: currentProfile.socials ?? [],
                    verification: currentProfile.verification,
                    achievement: currentProfile.achievement,
                    followers_count: newFollowersCount,
                    following_count: currentProfile.following_count,
                    friends_count: currentProfile.friends_count,
                    posts_count: currentProfile.posts_count,
                    ban: currentProfile.ban,
                    current_user_is_moderator: currentProfile.current_user_is_moderator,
                    is_private: currentProfile.is_private,
                    message: currentProfile.message
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

