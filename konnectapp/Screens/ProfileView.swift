import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = ProfileViewModel()
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
                        
                        if isOwnProfile {
                            CreatePostView(onPostCreated: {
                                Task {
                                    await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: 1)
                                }
                            })
                            .padding(.horizontal, 8)
                        }
                        
                        if viewModel.isLoadingPosts && viewModel.posts.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)
                        } else if viewModel.posts.isEmpty && !viewModel.isLoadingPosts {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                Text("Нет постов")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(viewModel.posts) { post in
                                PostCard(post: post, navigationPath: .constant(NavigationPath()))
                                    .padding(.horizontal, 8)
                            }
                            
                            if viewModel.hasMore {
                                Button(action: {
                                    Task {
                                        await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: viewModel.currentPage + 1)
                                    }
                                }) {
                                    Text("Загрузить еще")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                                        .padding()
                                }
                            }
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
                await viewModel.loadProfilePosts(userIdentifier: userIdentifier, page: 1)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView(viewModel: viewModel)
            }
        }
        .task(id: userIdentifier) {
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
    }
}

