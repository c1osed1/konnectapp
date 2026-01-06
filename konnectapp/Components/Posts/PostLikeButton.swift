import SwiftUI

struct PostLikeButton: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    @Binding var isLiking: Bool
    let onToggle: () async -> Void
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: {
                Task {
                    await onToggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isLiked ? .red : .white)
                    
                    if likesCount > 0 {
                        Text("\(likesCount)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .disabled(isLiking)
        } else {
            Button(action: {
                Task {
                    await onToggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isLiked ? .red : .white)
                    
                    if likesCount > 0 {
                        Text("\(likesCount)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.themeBlockBackground.opacity(0.9))
                        )
                )
            }
            .disabled(isLiking)
        }
    }
}

