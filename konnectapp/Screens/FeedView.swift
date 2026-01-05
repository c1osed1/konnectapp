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
        HStack(spacing: 0) {
            FeedTypeTab(title: "Все", type: .all, selected: $selectedFeedType)
            FeedTypeTab(title: "Подписки", type: .following, selected: $selectedFeedType)
            FeedTypeTab(title: "Рекомендации", type: .recommended, selected: $selectedFeedType)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct FeedTypeTab: View {
    let title: String
    let type: FeedType
    @Binding var selected: FeedType
    
    var body: some View {
        Button(action: {
            selected = type
        }) {
            Text(title)
                .font(.system(size: 15, weight: selected == type ? .semibold : .regular))
                .foregroundColor(selected == type ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }
}

struct PostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: post.user.avatar_url ?? "")) { image in
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
                            Text(String((post.user.name ?? post.user.username).prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.user.name ?? post.user.username)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if post.user.is_verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                        }
                    }
                    
                    Text("@\(post.user.username)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                
                Spacer()
                
                Text(formatDate(post.created_at))
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
            }
            
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
            
            if let media = post.media, !media.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(media, id: \.self) { mediaURL in
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
                        Image(systemName: post.is_liked ? "heart.fill" : "heart")
                            .foregroundColor(post.is_liked ? .red : Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(post.likes_count)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text("\(post.comments_count)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }
                
                if let repostsCount = post.reposts_count {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: post.is_reposted == true ? "arrow.2.squarepath" : "arrow.2.squarepath")
                                .foregroundColor(post.is_reposted == true ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
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
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let diff = now.timeIntervalSince(date)
            if diff < 60 {
                return "только что"
            } else if diff < 3600 {
                return "\(Int(diff / 60))м"
            } else {
                return "\(Int(diff / 3600))ч"
            }
        } else if calendar.isDateInYesterday(date) {
            return "вчера"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM"
            dateFormatter.locale = Locale(identifier: "ru_RU")
            return dateFormatter.string(from: date)
        }
    }
}
