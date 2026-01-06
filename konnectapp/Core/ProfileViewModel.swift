import Foundation
import Combine

enum ProfileTabType: Hashable {
    case posts
    case wall
    case about
}

class ProfileViewModel: ObservableObject {
    @Published var profile: ProfileResponse?
    @Published var posts: [Post] = []
    @Published var wallPosts: [Post] = []
    @Published var selectedTab: ProfileTabType = .posts
    @Published var isLoading: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var isLoadingWall: Bool = false
    @Published var hasMore: Bool = true
    @Published var hasMoreWall: Bool = true
    @Published var currentPage: Int = 1
    @Published var currentWallPage: Int = 1
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
                
                // Обновляем currentUser в AuthManager с полными данными из профиля
                // Это нужно для получения profile_background_url, которого нет в /api/auth/check
                let profileUser = profileResponse.user
                // Проверяем, что это профиль текущего пользователя
                let isCurrentUser = AuthManager.shared.currentUser?.id == profileUser.id
                
                if isCurrentUser {
                    // Создаем обновленного User с данными из ProfileUser
                    let updatedUser = User(
                        id: profileUser.id,
                        name: profileUser.name,
                        username: profileUser.username,
                        photo: profileUser.photo,
                        banner: profileUser.cover_photo, // cover_photo в ProfileUser = banner в User
                        about: profileUser.about,
                        avatar_url: profileUser.avatar_url,
                        banner_url: profileUser.banner_url,
                        profile_background_url: profileUser.profile_background_url,
                        profile_color: profileUser.profile_color,
                        hasCredentials: AuthManager.shared.currentUser?.hasCredentials, // Сохраняем старое значение
                        account_type: profileUser.account_type,
                        main_account_id: profileUser.main_account_id
                    )
                    AuthManager.shared.currentUser = updatedUser
                    print("🟢 ProfileViewModel: Updated currentUser with profile_background_url: \(profileUser.profile_background_url ?? "nil")")
                } else {
                    print("🔵 ProfileViewModel: Loaded profile for different user (\(profileUser.username)), not updating currentUser")
                }
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("⚠️ ProfileViewModel: Request was cancelled, but continuing to allow refresh...")
                // Не возвращаемся, чтобы позволить pull-to-refresh работать
                // Просто не устанавливаем ошибку
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
    
    func loadProfileWall(userIdentifier: String, page: Int = 1) async {
        await MainActor.run {
            isLoadingWall = true
        }
        
        defer {
            Task { @MainActor in
                isLoadingWall = false
            }
        }
        
        do {
            let feedResponse = try await ProfileService.shared.getProfileWall(
                userIdentifier: userIdentifier,
                page: page,
                perPage: 10
            )
            
            await MainActor.run {
                if page == 1 {
                    self.wallPosts = feedResponse.posts
                } else {
                    let existingIds = Set(self.wallPosts.map { $0.id })
                    let newPosts = feedResponse.posts.filter { !existingIds.contains($0.id) }
                    self.wallPosts.append(contentsOf: newPosts)
                }
                self.hasMoreWall = feedResponse.has_next
                self.currentWallPage = feedResponse.page
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func addWallPost(_ post: Post) {
        Task { @MainActor in
            // Добавляем пост в начало списка, если его еще нет
            if !wallPosts.contains(where: { $0.id == post.id }) {
                wallPosts.insert(post, at: 0)
            }
        }
    }
    
    func addPost(_ post: Post) {
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
            wallPosts.removeAll { $0.id == postId }
            // Обновляем счетчик постов в профиле
            if let currentProfile = profile {
                let currentPostsCount = currentProfile.posts_count ?? 0
                self.profile = ProfileResponse(
                    user: currentProfile.user,
                    is_following: currentProfile.is_following,
                    is_friend: currentProfile.is_friend,
                    notifications_enabled: currentProfile.notifications_enabled,
                    socials: currentProfile.socials ?? [],
                    verification: currentProfile.verification,
                    achievement: currentProfile.achievement,
                    followers_count: currentProfile.followers_count,
                    following_count: currentProfile.following_count,
                    friends_count: currentProfile.friends_count,
                    posts_count: max(0, currentPostsCount - 1),
                    ban: currentProfile.ban,
                    current_user_is_moderator: currentProfile.current_user_is_moderator,
                    is_private: currentProfile.is_private,
                    message: currentProfile.message
                )
            }
        }
    }
}

