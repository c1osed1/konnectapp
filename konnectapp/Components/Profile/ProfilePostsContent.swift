import SwiftUI

struct ProfilePostsContent: View {
    let posts: [Post]
    let isLoading: Bool
    let hasMore: Bool
    let currentPage: Int
    let userIdentifier: String
    let onLoadMore: () -> Void
    
    var body: some View {
        Group {
            if isLoading && posts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            } else if posts.isEmpty && !isLoading {
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

