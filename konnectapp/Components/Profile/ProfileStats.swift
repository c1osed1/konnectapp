import SwiftUI

struct ProfileStats: View {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            StatItem(count: postsCount, label: "Посты")
            
            Button(action: onFollowersTap) {
                StatItem(count: followersCount, label: "Подписчики")
            }
            
            Button(action: onFollowingTap) {
                StatItem(count: followingCount, label: "Подписки")
            }
        }
    }
}

struct StatItem: View {
    let count: Int
    let label: String
    
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
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                    )
            }
        )
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var fallbackStatItem: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                    )
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
}

