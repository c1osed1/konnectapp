import SwiftUI

struct ProfileActions: View {
    let isFollowing: Bool
    let isOwnProfile: Bool
    let onFollowToggle: () -> Void
    let onEdit: () -> Void
    let onMessage: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassActions
            } else {
                fallbackActions
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassActions: some View {
        HStack(spacing: 10) {
            if isOwnProfile {
                Button(action: onEdit) {
                    Text("Редактировать")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button(action: onFollowToggle) {
                    Text(isFollowing ? "Отписаться" : "Подписаться")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    @ViewBuilder
    private var fallbackActions: some View {
        HStack(spacing: 10) {
            if isOwnProfile {
                Button(action: onEdit) {
                    Text("Редактировать")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                }
            } else {
                Button(action: onFollowToggle) {
                    Text(isFollowing ? "Отписаться" : "Подписаться")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                }
                
                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                }
            }
        }
    }
}

