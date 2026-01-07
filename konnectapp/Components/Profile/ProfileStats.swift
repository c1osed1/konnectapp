import SwiftUI

struct ProfileStats: View {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void
    let useDarkText: Bool
    
    init(postsCount: Int, followersCount: Int, followingCount: Int, onFollowersTap: @escaping () -> Void, onFollowingTap: @escaping () -> Void, useDarkText: Bool = false) {
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.onFollowersTap = onFollowersTap
        self.onFollowingTap = onFollowingTap
        self.useDarkText = useDarkText
    }
    
    var body: some View {
        HStack(spacing: 8) {
            StatItem(count: postsCount, label: "Посты", useDarkText: useDarkText)
            
            Button(action: onFollowersTap) {
                StatItem(count: followersCount, label: "Подписчики", useDarkText: useDarkText)
            }
            
            Button(action: onFollowingTap) {
                StatItem(count: followingCount, label: "Подписки", useDarkText: useDarkText)
            }
        }
    }
}

struct StatItem: View {
    let count: Int
    let label: String
    let useDarkText: Bool
    
    init(count: Int, label: String, useDarkText: Bool = false) {
        self.count = count
        self.label = label
        self.useDarkText = useDarkText
    }
    
    private var textColor: Color {
        useDarkText ? Color.black : Color.white
    }
    
    private var secondaryTextColor: Color {
        useDarkText ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color(red: 0.7, green: 0.7, blue: 0.7)
    }
    
    private var borderColor: Color {
        // Светлосерый бордер для лучшей видимости на белом фоне
        useDarkText ? Color.gray.opacity(0.25) : Color.themeBorder.opacity(0.6)
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassStatItem
            } else {
                fallbackStatItem
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassStatItem: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private var fallbackStatItem: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
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

