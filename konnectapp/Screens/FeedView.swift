import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
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
            
            VStack(spacing: 0) {
                feedTypeTabs
                
                ScrollView {
                    LazyVStack(spacing: 16) {
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
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.loadInitialFeed()
                }
            }
        }
        .onAppear {
            if viewModel.posts.isEmpty {
                Task {
                    await viewModel.loadInitialFeed()
                }
            }
        }
        .onChange(of: selectedFeedType) { oldValue, newValue in
            Task {
                await viewModel.changeFeedType(newValue)
            }
        }
    }
    
    private var feedTypeTabs: some View {
        if #available(iOS 26.0, *) {
            liquidGlassTabs
        } else {
            fallbackTabs
        }
    }
    
    @available(iOS 26.0, *)
    private var liquidGlassTabs: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                FeedTypeTab(title: "Все", type: .all, selected: $selectedFeedType)
                FeedTypeTab(title: "Подписки", type: .following, selected: $selectedFeedType)
                FeedTypeTab(title: "Рекомендации", type: .recommended, selected: $selectedFeedType)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var fallbackTabs: some View {
        HStack(spacing: 0) {
            FeedTypeTab(title: "Все", type: .all, selected: $selectedFeedType)
            FeedTypeTab(title: "Подписки", type: .following, selected: $selectedFeedType)
            FeedTypeTab(title: "Рекомендации", type: .recommended, selected: $selectedFeedType)
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
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
            
            if !uniqueMedia.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(uniqueMedia, id: \.self) { mediaURL in
                            AsyncImage(url: URL(string: mediaURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                            }
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            
            HStack(spacing: 24) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: (post.is_liked ?? false) ? "heart.fill" : "heart")
                            .foregroundColor((post.is_liked ?? false) ? .red : Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(post.likes_count ?? 0)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(post.comments_count ?? 0)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                
                if let repostsCount = post.reposts_count {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: (post.is_reposted == true) ? "arrow.2.squarepath" : "arrow.2.squarepath")
                                .foregroundColor((post.is_reposted == true) ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                            Text("\(repostsCount)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
        )
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
