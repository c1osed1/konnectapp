import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var onlineUsersViewModel = OnlineUsersViewModel()
    @State private var selectedFeedType: FeedType = .all
    
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
                LazyVStack(spacing: 16) {
                    onlineUsersBlock
                        .padding(.top, 16)
                    
                    feedTypeTabs
                    
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
                            PostCard(post: post)
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
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .refreshable {
                await viewModel.loadInitialFeed()
                await onlineUsersViewModel.loadOnlineUsers()
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
                    ForEach(onlineUsersViewModel.onlineUsers.prefix(20), id: \.id) { user in
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
                .padding(.vertical, 8)
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
                ForEach(onlineUsersViewModel.onlineUsers.prefix(20), id: \.id) { user in
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
            .padding(.vertical, 8)
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
    
    private var feedTypeTabs: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassTabs
            } else {
                fallbackTabs
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassTabs: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                FeedTypeTab(title: "Все", type: .all, selected: $selectedFeedType)
                FeedTypeTab(title: "Подписки", type: .following, selected: $selectedFeedType)
            }
            .padding(.horizontal, 12)
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
    private var fallbackTabs: some View {
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PostCard: View {
    let post: Post
    
    private var uniqueMedia: [String] {
        var allMedia: [String] = []
        if let media = post.media {
            allMedia.append(contentsOf: media)
        }
        if let images = post.images {
            allMedia.append(contentsOf: images)
        }
        if let image = post.image, !allMedia.contains(image) {
            allMedia.append(image)
        }
        return Array(Set(allMedia))
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassPostCard
            } else {
                fallbackPostCard
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassPostCard: some View {
        GeometryReader { geometry in
            GlassEffectContainer(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    postContent
                    postActions
                }
                .frame(width: geometry.size.width - 32)
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
            .frame(width: geometry.size.width)
        }
        .frame(height: nil)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var fallbackPostCard: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                postContent
                postActions
            }
            .frame(width: geometry.size.width - 32)
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
            .frame(width: geometry.size.width)
        }
        .frame(height: nil)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var postContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                if let user = post.user {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: user.avatar_url ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
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
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            )
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(user.name ?? user.username)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if user.is_verified == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                                }
                            }
                            
                            Text("@\(user.username)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        }
                        
                        Spacer()
                        
                        if let createdAt = post.created_at ?? post.timestamp {
                            Text(formatDate(createdAt))
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        }
                    }
                }
                
                if let content = post.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
            }
            .padding(16)
            
            if !uniqueMedia.isEmpty {
                if uniqueMedia.count == 1 {
                    AsyncImage(url: URL(string: uniqueMedia[0])) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                .frame(height: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                .frame(height: 300)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else if uniqueMedia.count == 2 {
                    HStack(spacing: 2) {
                        ForEach(uniqueMedia, id: \.self) { mediaURL in
                            AsyncImage(url: URL(string: mediaURL)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                        .frame(height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                        .clipped()
                                case .failure:
                                    Rectangle()
                                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                        .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                } else if uniqueMedia.count == 3 {
                    VStack(spacing: 2) {
                        AsyncImage(url: URL(string: uniqueMedia[0])) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                    .frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        HStack(spacing: 2) {
                            ForEach(Array(uniqueMedia[1...2]), id: \.self) { mediaURL in
                                AsyncImage(url: URL(string: mediaURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                            .frame(height: 200)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 200)
                                            .clipped()
                                    case .failure:
                                        Rectangle()
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                            .frame(height: 200)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(Array(uniqueMedia.prefix(2)), id: \.self) { mediaURL in
                                AsyncImage(url: URL(string: mediaURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                            .frame(height: 150)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .clipped()
                                    case .failure:
                                        Rectangle()
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                            .frame(height: 150)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 2) {
                            ForEach(Array(uniqueMedia[2..<min(5, uniqueMedia.count)]), id: \.self) { mediaURL in
                                AsyncImage(url: URL(string: mediaURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ZStack {
                                            Rectangle()
                                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                                .frame(height: 150)
                                            
                                            if uniqueMedia.count > 5 && mediaURL == uniqueMedia[4] {
                                                Rectangle()
                                                    .fill(Color.black.opacity(0.6))
                                                    .frame(height: 150)
                                                
                                                Text("+\(uniqueMedia.count - 5)")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    case .success(let image):
                                        ZStack {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 150)
                                                .clipped()
                                            
                                            if uniqueMedia.count > 5 && mediaURL == uniqueMedia[4] {
                                                Rectangle()
                                                    .fill(Color.black.opacity(0.6))
                                                
                                                Text("+\(uniqueMedia.count - 5)")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    case .failure:
                                        ZStack {
                                            Rectangle()
                                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                                .frame(height: 150)
                                            
                                            if uniqueMedia.count > 5 && mediaURL == uniqueMedia[4] {
                                                Rectangle()
                                                    .fill(Color.black.opacity(0.6))
                                                    .frame(height: 150)
                                                
                                                Text("+\(uniqueMedia.count - 5)")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var postActions: some View {
        HStack(spacing: 12) {
            if #available(iOS 26.0, *) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: (post.is_liked ?? false) ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor((post.is_liked ?? false) ? .red : .white)
                        
                        if let likesCount = post.likes_count, likesCount > 0 {
                            Text("\(likesCount)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 36)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.roundedRectangle(radius: 18))
            } else {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: (post.is_liked ?? false) ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor((post.is_liked ?? false) ? .red : .white)
                        
                        if let likesCount = post.likes_count, likesCount > 0 {
                            Text("\(likesCount)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 36)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                }
            }
            
            if #available(iOS 26.0, *) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    
                    if let lastComment = post.last_comment, let commentUser = lastComment.user {
                        HStack(spacing: 6) {
                            AsyncImage(url: URL(string: commentUser.avatar_url ?? commentUser.photo ?? "")) { phase in
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
                                        .frame(width: 20, height: 20)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 20, height: 20)
                                        .clipShape(Circle())
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
                                        .frame(width: 20, height: 20)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                            Text(lastComment.content ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                .lineLimit(1)
                        }
                    } else {
                        Text("")
                            .font(.system(size: 14))
                            .italic()
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                    lineWidth: 0.5
                                )
                        )
                )
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    
                    if let lastComment = post.last_comment, let commentUser = lastComment.user {
                        HStack(spacing: 6) {
                            AsyncImage(url: URL(string: commentUser.avatar_url ?? commentUser.photo ?? "")) { phase in
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
                                        .frame(width: 20, height: 20)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 20, height: 20)
                                        .clipShape(Circle())
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
                                        .frame(width: 20, height: 20)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                            Text(lastComment.content ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                .lineLimit(1)
                        }
                    } else {
                        Text("Комментарий")
                            .font(.system(size: 14))
                            .italic()
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                    lineWidth: 0.5
                                )
                        )
                )
            }
            
            if #available(iOS 26.0, *) {
                Button(action: {}) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.roundedRectangle(radius: 18))
                .disabled(true)
            } else {
                Button(action: {}) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial.opacity(0.2))
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                }
                .disabled(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        var date: Date?
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let parsedDate = isoFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let parsedDate = isoFormatter.date(from: dateString) {
                date = parsedDate
            } else {
                let customFormatter = DateFormatter()
                customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let parsedDate = customFormatter.date(from: dateString) {
                    date = parsedDate
                } else {
                    customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    date = customFormatter.date(from: dateString)
                }
            }
        }
        
        guard let date = date else {
            print("⚠️ Failed to parse date: \(dateString)")
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        if diff < 60 {
            return "только что"
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            return "\(minutes) \(minutes == 1 ? "минуту" : minutes < 5 ? "минуты" : "минут") назад"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            if hours == 1 {
                return "1 час назад"
            } else if hours < 5 {
                return "\(hours) часа назад"
            } else {
                return "\(hours) часов назад"
            }
        } else if calendar.isDateInYesterday(date) {
            return "вчера"
        } else {
            let days = Int(diff / 86400)
            if days < 7 {
                return "\(days) \(days == 1 ? "день" : days < 5 ? "дня" : "дней") назад"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMM"
                dateFormatter.locale = Locale(identifier: "ru_RU")
                return dateFormatter.string(from: date)
            }
        }
    }
}
