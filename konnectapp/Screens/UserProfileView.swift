import SwiftUI

struct UserProfileView: View {
    let username: String
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showFollowers = false
    @State private var showFollowing = false
    @Environment(\.dismiss) private var dismiss
    
    private var isOwnProfile: Bool {
        AuthManager.shared.currentUser?.username == username
    }
    
    var body: some View {
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
                                        await viewModel.loadProfilePosts(userIdentifier: username, page: viewModel.currentPage + 1)
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
                await viewModel.loadProfile(userIdentifier: username)
                await viewModel.loadProfilePosts(userIdentifier: username, page: 1)
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
                    .foregroundColor(.white)
                }
            }
        }
        .task(id: username) {
            if viewModel.profile == nil {
                await viewModel.loadProfile(userIdentifier: username)
                await viewModel.loadProfilePosts(userIdentifier: username, page: 1)
            }
        }
    }
}

