import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showFollowers = false
    @State private var showFollowing = false
    @State private var showEditProfile = false
    
    private var userIdentifier: String {
        authManager.currentUser?.username ?? ""
    }
    
    private var isOwnProfile: Bool {
        true
    }
    
    var body: some View {
        ZStack {
            // Используем profile_background_url из загруженного профиля, если он есть
            AppBackgroundView(backgroundURL: viewModel.profile?.user.profile_background_url ?? authManager.currentUser?.profile_background_url)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    if let profile = viewModel.profile {
                        ProfileCard(
                            profile: profile.user,
                            socials: profile.socials,
                            isFollowing: profile.is_following ?? false,
                            isOwnProfile: isOwnProfile,
                            onFollowToggle: {
                                Task {
                                    await viewModel.toggleFollow()
                                }
                            },
                            onEdit: {
                                showEditProfile = true
                            },
                            onMessage: {
                                // TODO: Open messages
                            },
                            onFollowersTap: {
                                showFollowers = true
                            },
                            onFollowingTap: {
                                showFollowing = true
                            }
                        )
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        
                        // CreatePost для владельца профиля (на вкладке "Посты")
                        if isOwnProfile && viewModel.selectedTab == .posts {
                            CreatePostView(
                                onPostCreated: { createdPost in
                                    if let post = createdPost {
                                        viewModel.addPost(post)
                                    } else {
                                Task {
                                    await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: 1)
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal, 8)
                        }
                        
                        // CreatePost для стены (видно всем на вкладке "Стена")
                        if viewModel.selectedTab == .wall {
                            CreatePostView(
                                onPostCreated: { createdPost in
                                    if let post = createdPost {
                                        viewModel.addWallPost(post)
                                    } else {
                                        Task {
                                            await viewModel.loadProfileWall(userIdentifier: userIdentifier, page: 1)
                            }
                                    }
                                },
                                postType: "stena",
                                recipientId: viewModel.profile?.user.id
                            )
                                    .padding(.horizontal, 8)
                            }
                            
                        // Табы для переключения между постами и стеной
                        ProfileTabsView(selectedTab: $viewModel.selectedTab)
                            .padding(.horizontal, 8)
                        
                        // Контент в зависимости от выбранного таба
                        if viewModel.selectedTab == .posts {
                            ProfilePostsContent(
                                posts: viewModel.posts,
                                isLoading: viewModel.isLoadingPosts,
                                hasMore: viewModel.hasMore,
                                currentPage: viewModel.currentPage,
                                userIdentifier: userIdentifier,
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: viewModel.currentPage + 1)
                                    }
                                }
                            )
                        } else if viewModel.selectedTab == .wall {
                            ProfileWallContent(
                                wallPosts: viewModel.wallPosts,
                                isLoading: viewModel.isLoadingWall,
                                hasMore: viewModel.hasMoreWall,
                                currentPage: viewModel.currentWallPage,
                                userIdentifier: userIdentifier,
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadProfileWall(userIdentifier: userIdentifier, page: viewModel.currentWallPage + 1)
                                    }
                                }
                            )
                        } else {
                            ProfileAboutContent(
                                profile: profile.user,
                                socials: profile.socials,
                                isPrivate: profile.is_private,
                                isFriend: profile.is_friend,
                                isOwnProfile: isOwnProfile
                            )
                        }
                    } else if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 100)
                    }
                }
                .padding(.bottom, 100)
            }
            .refreshable {
                await viewModel.loadProfile(userIdentifier: userIdentifier)
                if viewModel.selectedTab == .posts {
                await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: 1)
                } else {
                    await viewModel.loadProfileWall(userIdentifier: userIdentifier, page: 1)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView(viewModel: viewModel)
            }
        }
        .task {
            print("🔵 ProfileView: task started")
            print("🔵 ProfileView: userIdentifier: '\(userIdentifier)'")
            print("🔵 ProfileView: authManager.currentUser: \(authManager.currentUser?.username ?? "nil")")
            
            guard !userIdentifier.isEmpty else {
                print("❌ ProfileView: userIdentifier is empty, cannot load profile")
                await MainActor.run {
                    viewModel.errorMessage = "Не удалось определить пользователя"
                }
                return
            }
            
            if viewModel.profile == nil {
                print("🔵 ProfileView: Profile is nil, loading...")
                await viewModel.loadProfile(userIdentifier: userIdentifier)
                print("🔵 ProfileView: Profile loaded, now loading posts...")
                await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: 1)
                print("✅ ProfileView: All data loaded")
            } else {
                print("✅ ProfileView: Profile already exists")
            }
        }
        .onChange(of: viewModel.selectedTab) { oldValue, newValue in
            Task {
                if newValue == .posts && viewModel.posts.isEmpty {
                    await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: 1)
                } else if newValue == .wall && viewModel.wallPosts.isEmpty {
                    await viewModel.loadProfileWall(userIdentifier: userIdentifier, page: 1)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostDeleted"))) { notification in
            if let postId = notification.userInfo?["postId"] as? Int64 {
                viewModel.removePost(postId: postId)
            }
        }
    }
    
}

