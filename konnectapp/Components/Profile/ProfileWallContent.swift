import SwiftUI

struct ProfileWallContent: View {
    let wallPosts: [Post]
    let isLoading: Bool
    let hasMore: Bool
    let currentPage: Int
    let userIdentifier: String
    let onLoadMore: () -> Void
    
    var body: some View {
        Group {
            if isLoading && wallPosts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            } else if wallPosts.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    Text("Стена пуста")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                }
                .padding(.top, 40)
            } else {
                ForEach(wallPosts) { post in
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

