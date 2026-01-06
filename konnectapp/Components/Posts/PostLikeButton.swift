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
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
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
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
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
            .disabled(isLiking)
        }
    }
}

