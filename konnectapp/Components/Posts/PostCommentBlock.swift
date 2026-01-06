import SwiftUI

struct PostCommentBlock: View {
    let lastComment: Comment?
    let onTap: (() -> Void)?
    
    init(lastComment: Comment?, onTap: (() -> Void)? = nil) {
        self.lastComment = lastComment
        self.onTap = onTap
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            Group {
                if #available(iOS 26.0, *) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                
                if let lastComment = lastComment, let commentUser = lastComment.user {
                    HStack(spacing: 6) {
                        AsyncImage(url: URL(string: commentUser.avatar_url ?? commentUser.photo ?? "")) { phase in
                            switch phase {
                            case .empty:
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
                                                Color.appAccent,
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
                    Text("тут пусто")
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
                    .fill(.ultraThinMaterial.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.appAccent.opacity(0.15),
                                lineWidth: 0.5
                            )
                    )
            )
        } else {
            HStack(spacing: 8) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                
                if let lastComment = lastComment, let commentUser = lastComment.user {
                    HStack(spacing: 6) {
                        AsyncImage(url: URL(string: commentUser.avatar_url ?? commentUser.photo ?? "")) { phase in
                            switch phase {
                            case .empty:
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
                                                Color.appAccent,
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
                    .fill(.ultraThinMaterial.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.appAccent.opacity(0.15),
                                lineWidth: 0.5
                            )
                    )
            )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

