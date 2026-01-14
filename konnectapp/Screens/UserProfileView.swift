import SwiftUI

struct UserProfileView: View {
    let username: String
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showFollowers = false
    @State private var showFollowing = false
    @Environment(\.dismiss) private var dismiss
    
    private var isOwnProfile: Bool {
        AuthManager.shared.currentUser?.username == username
    }
    
    private var canCreateWallPost: Bool {
        !isOwnProfile && viewModel.profile != nil
    }
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: viewModel.profile?.user.profile_background_url)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    if let profile = viewModel.profile {
                        ProfileCard(
                            profile: profile.user,
                            socials: profile.socials,
                            isFollowing: profile.is_following ?? false,
                            isOwnProfile: isOwnProfile,
                            achievement: profile.achievement,
                            onFollowToggle: {
                                Task {
                                    await viewModel.toggleFollow()
                                }
                            },
                            onEdit: {
                                // TODO: Open edit profile
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
                        
                        // Табы для переключения между постами и стеной
                        ProfileTabsView(selectedTab: $viewModel.selectedTab)
                            .padding(.horizontal, 8)
                        
                        // CreatePost для стены (видно всем на вкладке "Стена")
                        if viewModel.selectedTab == .wall {
                            CreatePostView(
                                onPostCreated: { createdPost in
                                    if let post = createdPost {
                                        viewModel.addWallPost(post)
                                    } else {
                                        Task {
                                            await viewModel.loadProfileWall(userIdentifier: username, page: 1)
                            }
                                    }
                                },
                                postType: "stena",
                                recipientId: viewModel.profile?.user.id
                            )
                                    .padding(.horizontal, 8)
                            }
                        
                        // Контент в зависимости от выбранного таба
                        if viewModel.selectedTab == .posts {
                            ProfilePostsContent(
                                posts: viewModel.posts,
                                pinnedPost: viewModel.pinnedPost,
                                profileUser: viewModel.profile?.user,
                                isLoading: viewModel.isLoadingPosts,
                                hasMore: viewModel.hasMore,
                                currentPage: viewModel.currentPage,
                                userIdentifier: username,
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadProfilePosts(userIdentifier: username, page: viewModel.currentPage + 1)
                                    }
                                }
                            )
                        } else if viewModel.selectedTab == .wall {
                            ProfileWallContent(
                                wallPosts: viewModel.wallPosts,
                                isLoading: viewModel.isLoadingWall,
                                hasMore: viewModel.hasMoreWall,
                                currentPage: viewModel.currentWallPage,
                                userIdentifier: username,
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadProfileWall(userIdentifier: username, page: viewModel.currentWallPage + 1)
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
                                .foregroundColor(Color.themeTextPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 100)
                    }
                }
                .padding(.bottom, 100)
            }
            .refreshable {
                await viewModel.loadProfile(userIdentifier: username)
                if viewModel.selectedTab == .posts {
                await viewModel.loadProfilePosts(userIdentifier: username, page: 1)
                } else {
                    await viewModel.loadProfileWall(userIdentifier: username, page: 1)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Назад")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(Color.themeTextPrimary)
                }
            }
        }
        .task {
            if viewModel.profile == nil {
                await viewModel.loadProfile(userIdentifier: username)
                await viewModel.loadProfilePosts(userIdentifier: username, page: 1)
            }
        }
        .onChange(of: viewModel.selectedTab) { oldValue, newValue in
            Task {
                if newValue == .posts && viewModel.posts.isEmpty {
                    await viewModel.loadProfilePosts(userIdentifier: username, page: 1)
                } else if newValue == .wall && viewModel.wallPosts.isEmpty {
                    await viewModel.loadProfileWall(userIdentifier: username, page: 1)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostDeleted"))) { notification in
            if let postId = notification.userInfo?["postId"] as? Int64 {
                viewModel.removePost(postId: postId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostUpdated"))) { notification in
            if let post = notification.userInfo?["post"] as? Post {
                viewModel.updatePost(post)
            }
        }
    }
    
}

