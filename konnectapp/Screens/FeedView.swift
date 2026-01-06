import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var onlineUsersViewModel = OnlineUsersViewModel()
    @State private var selectedFeedType: FeedType = .all
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: AuthManager.shared.currentUser?.profile_background_url)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    onlineUsersBlock
                        .padding(.top, 8)
                    
                    CreatePostView {
                        Task {
                            await viewModel.loadInitialFeed()
                        }
                    }
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                // Prevent dismissing keyboard when tapping inside CreatePostView
                            }
                    )
                    
                    feedTypeTabsView
                    
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                    } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            Text("Лента пуста")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                            
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
                                            .fill(Color(red: 0.82, green: 0.74, blue: 1.0))
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
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                .padding()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 100)
            }
            .refreshable {
                await viewModel.loadInitialFeed()
                await onlineUsersViewModel.loadOnlineUsers()
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
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var onlineUsersBlock: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassOnlineBlock
            } else {
                fallbackOnlineBlock
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassOnlineBlock: some View {
        GlassEffectContainer(spacing: 0) {
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
                            AsyncImage(url: URL(string: user.photo ?? user.avatar_url ?? "")) { phase in
                                switch phase {
                                case .empty:
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.82, green: 0.74, blue: 1.0),
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
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.82, green: 0.74, blue: 1.0),
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
                                @unknown default:
                                    EmptyView()
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
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                }
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
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
                        AsyncImage(url: URL(string: user.photo ?? user.avatar_url ?? "")) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.82, green: 0.74, blue: 1.0),
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
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.82, green: 0.74, blue: 1.0),
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
                            @unknown default:
                                EmptyView()
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
                    .fill(.ultraThinMaterial.opacity(0.2))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
    
    private var feedTypeTabsView: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassTabsView
            } else {
                fallbackTabsView
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassTabsView: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                FeedTypeTab(title: "Все", type: .all, selected: $selectedFeedType)
                FeedTypeTab(title: "Подписки", type: .following, selected: $selectedFeedType)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                }
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    @ViewBuilder
    private var fallbackTabsView: some View {
        HStack(spacing: 0) {
            FeedTypeTab(title: "Все", type: .all, selected: $selectedFeedType)
            FeedTypeTab(title: "Подписки", type: .following, selected: $selectedFeedType)
            FeedTypeTab(title: "Рекомендации", type: .recommended, selected: $selectedFeedType)
        }
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.2))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
}

struct FeedTypeTab: View {
    let title: String
    let type: FeedType
    @Binding var selected: FeedType
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = type
            }
        }) {
            ZStack {
                if selected == type {
                    Capsule()
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.4))
                        .frame(height: 32)
                        .padding(.horizontal, 4)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: selected == type ? .semibold : .regular))
                    .foregroundColor(selected == type ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}