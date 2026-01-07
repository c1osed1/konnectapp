import SwiftUI

struct ProfileActions: View {
    let isFollowing: Bool
    let isOwnProfile: Bool
    let onFollowToggle: () -> Void
    let onEdit: () -> Void
    let onMessage: () -> Void
    let useDarkText: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    init(isFollowing: Bool, isOwnProfile: Bool, onFollowToggle: @escaping () -> Void, onEdit: @escaping () -> Void, onMessage: @escaping () -> Void, useDarkText: Bool = false) {
        self.isFollowing = isFollowing
        self.isOwnProfile = isOwnProfile
        self.onFollowToggle = onFollowToggle
        self.onEdit = onEdit
        self.onMessage = onMessage
        self.useDarkText = useDarkText
    }
    
    private var textColor: Color {
        useDarkText ? Color.black : Color.white
    }
    
    private var borderColor: Color {
        // Светлосерый бордер для лучшей видимости на белом фоне
        // На светлой теме используем серый, на темной - более светлый
        useDarkText ? Color.gray.opacity(0.25) : Color.themeBorder.opacity(0.6)
    }
    
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
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 0.5)
                        )
                }
            } else {
                Button(action: onFollowToggle) {
                    Text(isFollowing ? "Отписаться" : "Подписаться")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 0.5)
                        )
                }
                
                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(textColor)
                        .frame(width: 44, height: 44)
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 0.5)
                        )
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
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(borderColor, lineWidth: 0.5)
                                )
                        )
                }
            } else {
                Button(action: onFollowToggle) {
                    Text(isFollowing ? "Отписаться" : "Подписаться")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(borderColor, lineWidth: 0.5)
                                )
                        )
                }
                
                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(textColor)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(borderColor, lineWidth: 0.5)
                                )
                        )
                }
            }
        }
    }
}

