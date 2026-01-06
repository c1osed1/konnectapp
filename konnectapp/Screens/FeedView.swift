import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var onlineUsersViewModel = OnlineUsersViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedFeedType: FeedType = .all
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: AuthManager.shared.currentUser?.profile_background_url)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    onlineUsersBlock
                        .padding(.top, 8)
                    
                    CreatePostView { createdPost in
                        if let post = createdPost {
                            viewModel.addPostToFeed(post)
                        } else {
                            Task {
                                await viewModel.loadInitialFeed()
                            }
                        }
                    }
                    
                    feedTypeTabsView
                    
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                    } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(Color.themeTextSecondary)
                            Text("Лента пуста")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.themeTextPrimary)
                            
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.96, green: 0.26, blue: 0.21))
                                    .padding(.top, 8)
                            }
                            
                            Button(action: {
                                Task {
                                    await viewModel.loadInitialFeed()
                                }
                            }) {
                                Text("Обновить")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.appAccent)
                                    )
                            }
                            .padding(.top, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        ForEach(viewModel.posts) { post in
                            PostCard(post: post, navigationPath: $navigationPath)
                                .onAppear {
                                    if post.id == viewModel.posts.last?.id {
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                                }
                        }
                        
                        if viewModel.hasMore && !viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                        
                        if !viewModel.hasMore && !viewModel.posts.isEmpty {
                            Text("Конец ленты")
                                .font(.system(size: 14))
                                .foregroundColor(Color.themeTextSecondary)
                                .padding()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 100)
            }
            .refreshable {
                // Запускаем обе задачи параллельно
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await viewModel.loadInitialFeed()
                    }
                    group.addTask {
                        await onlineUsersViewModel.loadOnlineUsers()
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadInitialFeed()
            }
            await onlineUsersViewModel.loadOnlineUsers()
            onlineUsersViewModel.startAutoUpdate()
        }
        .onDisappear {
            onlineUsersViewModel.stopAutoUpdate()
        }
        .onChange(of: selectedFeedType) { oldValue, newValue in
            Task {
                await viewModel.changeFeedType(newValue)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostDeleted"))) { notification in
            if let postId = notification.userInfo?["postId"] as? Int64 {
                viewModel.removePost(postId: postId)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var onlineUsersBlock: some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassOnlineBlock
            } else {
                fallbackOnlineBlock
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassOnlineBlock: some View {
        let content = ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if onlineUsersViewModel.onlineUsers.isEmpty {
                    skeletonUsers
                } else {
                    onlineUsersList
                }
            }
            .padding(.vertical, 8)
            .padding(.leading, 15)
            .padding(.trailing, 15)
        }
        content.glassEffect(.regularInteractive, in: RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var skeletonUsers: some View {
        ForEach(0..<10, id: \.self) { _ in
            SkeletonCircle(size: 44)
                .overlay(
                    Circle()
                        .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                        .frame(width: 12, height: 12)
                        .offset(x: 16, y: 16)
                )
        }
    }
    
    @ViewBuilder
    private var onlineUsersList: some View {
        ForEach(onlineUsersViewModel.onlineUsers.prefix(20), id: \.id) { user in
            Button(action: {
                navigationPath.append(user.username)
            }) {
                userAvatarView(user: user)
            }
        }
    }
    
    @ViewBuilder
    private func userAvatarView(user: PostUser) -> some View {
        Group {
            if let avatarURL = user.photo ?? user.avatar_url, let url = URL(string: avatarURL) {
                CachedAsyncImage(url: url, cacheType: .avatar)
                    .aspectRatio(contentMode: .fill)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appAccent,
                                Color(red: 0.75, green: 0.65, blue: 0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text(String((user.name ?? user.username).prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    )
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.2), lineWidth: 2)
                        .frame(width: 12, height: 12)
                )
                .offset(x: 16, y: 16)
        )
    }
    
    @ViewBuilder
    private var fallbackOnlineBlock: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if onlineUsersViewModel.onlineUsers.isEmpty {
                    ForEach(0..<10, id: \.self) { _ in
                        SkeletonCircle(size: 44)
                            .overlay(
                                Circle()
                                    .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                                    .frame(width: 12, height: 12)
                                    .offset(x: 16, y: 16)
                            )
                    }
                } else {
                    ForEach(onlineUsersViewModel.onlineUsers.prefix(20), id: \.id) { user in
                        Button(action: {
                            navigationPath.append(user.username)
                        }) {
                            Group {
                                if let avatarURL = user.photo ?? user.avatar_url, let url = URL(string: avatarURL) {
                                    CachedAsyncImage(url: url, cacheType: .avatar)
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.appAccent,
                                                    Color(red: 0.75, green: 0.65, blue: 0.95)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            Text(String((user.name ?? user.username).prefix(1)))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.black)
                                        )
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.2), lineWidth: 2)
                                            .frame(width: 12, height: 12)
                                    )
                                    .offset(x: 16, y: 16)
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.leading, 15)
            .padding(.trailing, 15)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
    
    private var feedTypeTabsView: some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                Picker("", selection: $selectedFeedType) {
                    Text("Все").tag(FeedType.all)
                    Text("Подписки").tag(FeedType.following)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .font(.system(size: 16, weight: .medium))
                .frame(height: 48)
                .padding(.horizontal, 2)
                .glassEffect(in: RoundedRectangle(cornerRadius: 24))
            } else {
                Picker("", selection: $selectedFeedType) {
                    Text("Все").tag(FeedType.all)
                    Text("Подписки").tag(FeedType.following)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .font(.system(size: 16, weight: .medium))
                .frame(height: 48)
                .padding(.horizontal, 8)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.themeBlockBackground.opacity(0.9))
                            )
                        
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color.appAccent.opacity(0.15),
                                lineWidth: 0.5
                            )
                    }
                )
            }
        }
    }
}