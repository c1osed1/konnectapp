import SwiftUI

struct ProfileCard: View {
    let profile: ProfileUser
    let socials: [Social]?
    let isFollowing: Bool
    let isOwnProfile: Bool
    let onFollowToggle: () -> Void
    let onEdit: () -> Void
    let onMessage: () -> Void
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void
    
    private var borderColor: Color {
        if let profileColor = profile.profile_color, let color = Color(hex: profileColor) {
            return color
        }
        if let statusColor = profile.status_color, let color = Color(hex: statusColor) {
            return color
        }
        if let subscription = profile.subscription {
            switch subscription.type {
            case "premium":
                return Color(red: 186/255, green: 104/255, blue: 200/255)
            case "pick-me":
                return Color(red: 208/255, green: 188/255, blue: 255/255)
            case "ultimate":
                return Color(red: 124/255, green: 77/255, blue: 255/255)
            case "max":
                return Color(red: 208/255, green: 7/255, blue: 7/255)
            default:
                return Color(red: 66/255, green: 165/255, blue: 245/255)
            }
        }
        return Color(red: 66/255, green: 165/255, blue: 245/255)
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassProfileCard
            } else {
                fallbackProfileCard
            }
        }
    }
    
    private var isBannerBackground: Bool {
        profile.profile_id == 2 || profile.profile_id == 3
    }
    
    private var statusColor: Color {
        if let statusColor = profile.status_color, let color = Color(hex: statusColor) {
            return color
        }
        if let profileColor = profile.profile_color, let color = Color(hex: profileColor) {
            return color
        }
        return Color(red: 0.82, green: 0.74, blue: 1.0)
    }
    
    private func verificationStatusColor(_ status: VerificationStatus?) -> Color? {
        guard let status = status else { return nil }
        
        switch status {
        case .verified:
            return Color.orange
        case .custom(3):
            return Color.purple
        case .rejected:
            return Color.red
        case .pending:
            return Color.gray
        default:
            return nil
        }
    }
    
    private func shouldShowVerificationIcon(_ status: VerificationStatus?) -> Bool {
        guard let status = status else { return false }
        
        switch status {
        case .verified, .custom(3), .rejected, .pending:
            return true
        default:
            return false
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassProfileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isBannerBackground {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(profile.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                                
                                if shouldShowVerificationIcon(profile.verification_status) {
                                    if let statusColor = verificationStatusColor(profile.verification_status) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(statusColor)
                                            .font(.system(size: 18, weight: .semibold))
                                            .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                                    }
                                }
                                
                                if let scam = profile.scam, scam.isScam {
                                    Text("SCAM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.red)
                                        )
                                        .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                                }
                            }
                            
                            Text("@\(profile.username)")
                                .font(.system(size: 15))
                                .foregroundColor(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                            
                            if let statusText = profile.status_text {
                                Text(cleanStatusText(statusText))
                                    .font(.system(size: 14))
                                    .foregroundColor(statusColor)
                                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 140)
                    
                    ProfileStats(
                        postsCount: profile.posts_count ?? 0,
                        followersCount: profile.followers_count ?? 0,
                        followingCount: profile.following_count ?? 0,
                        onFollowersTap: onFollowersTap,
                        onFollowingTap: onFollowingTap
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    ProfileActions(
                        isFollowing: isFollowing,
                        isOwnProfile: isOwnProfile,
                        onFollowToggle: onFollowToggle,
                        onEdit: onEdit,
                        onMessage: onMessage
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    if let about = profile.about, !about.isEmpty {
                        Text(about)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial.opacity(0.2))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                                        )
                                }
                            )
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    if let socials = socials, !socials.isEmpty {
                        ProfileSocials(socials: Array(socials.prefix(2)))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
                .frame(minHeight: 400)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if let bannerURL = profile.banner_url, let url = URL(string: bannerURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.1, green: 0.1, blue: 0.1),
                                                    Color(red: 0.15, green: 0.15, blue: 0.15)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipped()
                                case .failure:
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.1, green: 0.1, blue: 0.1),
                                                    Color(red: 0.15, green: 0.15, blue: 0.15)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.1, green: 0.1, blue: 0.1),
                                            Color(red: 0.15, green: 0.15, blue: 0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                )
                .overlay(alignment: .topLeading) {
                    ProfileAvatar(
                        avatarURL: profile.avatar_url,
                        size: 110,
                        borderColor: borderColor,
                        isOnline: false
                    )
                    .offset(x: 16, y: 16)
                    .zIndex(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ProfileBanner(bannerURL: profile.banner_url, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        ProfileAvatar(
                            avatarURL: profile.avatar_url,
                            size: 110,
                            borderColor: borderColor,
                            isOnline: false
                        )
                        .offset(x: 16, y: 55)
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(profile.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if shouldShowVerificationIcon(profile.verification_status) {
                                    if let statusColor = verificationStatusColor(profile.verification_status) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(statusColor)
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                
                                if let scam = profile.scam, scam.isScam {
                                    Text("SCAM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.red)
                                        )
                                }
                            }
                            
                            Text("@\(profile.username)")
                                .font(.system(size: 15))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            if let statusText = profile.status_text {
                                Text(cleanStatusText(statusText))
                                    .font(.system(size: 14))
                                    .foregroundColor(statusColor)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 16)
                    
                    ProfileStats(
                        postsCount: profile.posts_count ?? 0,
                        followersCount: profile.followers_count ?? 0,
                        followingCount: profile.following_count ?? 0,
                        onFollowersTap: onFollowersTap,
                        onFollowingTap: onFollowingTap
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.3))
                    )
                    
                    ProfileActions(
                        isFollowing: isFollowing,
                        isOwnProfile: isOwnProfile,
                        onFollowToggle: onFollowToggle,
                        onEdit: onEdit,
                        onMessage: onMessage
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    if let about = profile.about, !about.isEmpty {
                        Text(about)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial.opacity(0.2))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                            lineWidth: 0.5
                                        )
                                }
                            )
                    }
                    
                    if let socials = socials, !socials.isEmpty {
                        ProfileSocials(socials: Array(socials.prefix(2)))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.2))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var fallbackProfileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isBannerBackground {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(profile.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                                
                                if shouldShowVerificationIcon(profile.verification_status) {
                                    if let statusColor = verificationStatusColor(profile.verification_status) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(statusColor)
                                            .font(.system(size: 18, weight: .semibold))
                                            .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                                    }
                                }
                                
                                if let scam = profile.scam, scam.isScam {
                                    Text("SCAM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.red)
                                        )
                                        .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                                }
                            }
                            
                            Text("@\(profile.username)")
                                .font(.system(size: 15))
                                .foregroundColor(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                            
                            if let statusText = profile.status_text {
                                Text(cleanStatusText(statusText))
                                    .font(.system(size: 14))
                                    .foregroundColor(statusColor)
                                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 140)
                    
                    ProfileStats(
                        postsCount: profile.posts_count ?? 0,
                        followersCount: profile.followers_count ?? 0,
                        followingCount: profile.following_count ?? 0,
                        onFollowersTap: onFollowersTap,
                        onFollowingTap: onFollowingTap
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    ProfileActions(
                        isFollowing: isFollowing,
                        isOwnProfile: isOwnProfile,
                        onFollowToggle: onFollowToggle,
                        onEdit: onEdit,
                        onMessage: onMessage
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    if let about = profile.about, !about.isEmpty {
                        Text(about)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial.opacity(0.2))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                            lineWidth: 0.5
                                        )
                                }
                            )
                    }
                    
                    if let socials = socials, !socials.isEmpty {
                        ProfileSocials(socials: Array(socials.prefix(2)))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
                .frame(minHeight: 400)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if let bannerURL = profile.banner_url, let url = URL(string: bannerURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.1, green: 0.1, blue: 0.1),
                                                    Color(red: 0.15, green: 0.15, blue: 0.15)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipped()
                                case .failure:
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.1, green: 0.1, blue: 0.1),
                                                    Color(red: 0.15, green: 0.15, blue: 0.15)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.1, green: 0.1, blue: 0.1),
                                            Color(red: 0.15, green: 0.15, blue: 0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                )
                .overlay(alignment: .topLeading) {
                    ProfileAvatar(
                        avatarURL: profile.avatar_url,
                        size: 110,
                        borderColor: borderColor,
                        isOnline: false
                    )
                    .offset(x: 16, y: 16)
                    .zIndex(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ProfileBanner(bannerURL: profile.banner_url, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        ProfileAvatar(
                            avatarURL: profile.avatar_url,
                            size: 110,
                            borderColor: borderColor,
                            isOnline: false
                        )
                        .offset(x: 16, y: 55)
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(profile.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if shouldShowVerificationIcon(profile.verification_status) {
                                    if let statusColor = verificationStatusColor(profile.verification_status) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(statusColor)
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                
                                if let scam = profile.scam, scam.isScam {
                                    Text("SCAM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.red)
                                        )
                                }
                            }
                            
                            Text("@\(profile.username)")
                                .font(.system(size: 15))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            if let statusText = profile.status_text {
                                Text(cleanStatusText(statusText))
                                    .font(.system(size: 14))
                                    .foregroundColor(statusColor)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 16)
                    
                    ProfileStats(
                        postsCount: profile.posts_count ?? 0,
                        followersCount: profile.followers_count ?? 0,
                        followingCount: profile.following_count ?? 0,
                        onFollowersTap: onFollowersTap,
                        onFollowingTap: onFollowingTap
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.3))
                    )
                    
                    ProfileActions(
                        isFollowing: isFollowing,
                        isOwnProfile: isOwnProfile,
                        onFollowToggle: onFollowToggle,
                        onEdit: onEdit,
                        onMessage: onMessage
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    if let about = profile.about, !about.isEmpty {
                        Text(about)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial.opacity(0.2))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                            lineWidth: 0.5
                                        )
                                }
                            )
                    }
                    
                    if let socials = socials, !socials.isEmpty {
                        ProfileSocials(socials: Array(socials.prefix(2)))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.2))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
}
