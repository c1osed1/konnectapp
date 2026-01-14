import SwiftUI

struct ProfilePostsContent: View {
    let posts: [Post]
    let pinnedPost: Post?
    let profileUser: ProfileUser?
    let isLoading: Bool
    let hasMore: Bool
    let currentPage: Int
    let userIdentifier: String
    let onLoadMore: () -> Void

    private var profileAccent: Color {
        Color.accentColor(from: profileUser)
    }
    
    var body: some View {
        Group {
            if isLoading && posts.isEmpty && pinnedPost == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            } else if posts.isEmpty && pinnedPost == nil && !isLoading {
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
                // Показываем закрепленный пост первым
                if let pinned = pinnedPost {
                    PostCard(
                        post: pinned,
                        navigationPath: .constant(NavigationPath()),
                        forcePinnedStyle: true,
                        pinnedAccentColor: profileAccent
                    )
                        .padding(.horizontal, 8)
                }
                
                ForEach(posts) { post in
                    PostCard(post: post, navigationPath: .constant(NavigationPath()))
                        .padding(.horizontal, 8)
                }
                
                if hasMore {
                    Button(action: onLoadMore) {
                        Text("Загрузить еще")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.appAccent)
                            .padding()
                    }
                }
            }
        }
    }
}

