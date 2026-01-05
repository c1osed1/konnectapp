import SwiftUI

struct ProfileSocials: View {
    let socials: [Social]
    
    private var limitedSocials: [Social] {
        Array(socials.prefix(2))
    }
    
    var body: some View {
        if !limitedSocials.isEmpty {
            HStack(spacing: 8) {
                ForEach(limitedSocials, id: \.name) { social in
                    SocialButton(social: social)
                        .frame(maxWidth: limitedSocials.count == 1 ? .infinity : nil)
                }
            }
        }
    }
}

struct SocialButton: View {
    let social: Social
    @Environment(\.openURL) private var openURL
    
    private var iconName: String {
        let name = social.name.lowercased()
        if name.contains("instagram") {
            return "camera.fill"
        } else if name.contains("facebook") {
            return "f.circle.fill"
        } else if name.contains("twitter") || name.contains("x") {
            return "at"
        } else if name.contains("vk") {
            return "v.circle.fill"
        } else if name.contains("youtube") {
            return "play.rectangle.fill"
        } else if name.contains("telegram") {
            return "paperplane.fill"
        } else if name.contains("element") {
            return "message.fill"
        } else {
            return "link"
        }
    }
    
    private var iconColor: Color {
        let name = social.name.lowercased()
        if name.contains("instagram") {
            return Color(red: 0.9, green: 0.3, blue: 0.5)
        } else if name.contains("facebook") {
            return Color(red: 0.26, green: 0.4, blue: 0.7)
        } else if name.contains("twitter") || name.contains("x") {
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        } else if name.contains("vk") {
            return Color(red: 0.3, green: 0.5, blue: 0.8)
        } else if name.contains("youtube") {
            return Color(red: 1.0, green: 0.0, blue: 0.0)
        } else if name.contains("telegram") {
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        } else if name.contains("element") {
            return Color(red: 0.82, green: 0.74, blue: 1.0)
        } else {
            return Color(red: 0.82, green: 0.74, blue: 1.0)
        }
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassButton
            } else {
                fallbackButton
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassButton: some View {
        Button(action: {
            if let url = URL(string: social.link) {
                openURL(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                
                Text(social.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                }
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private var fallbackButton: some View {
        Button(action: {
            if let url = URL(string: social.link) {
                openURL(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                
                Text(social.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                            lineWidth: 0.5
                        )
                }
            )
        }
    }
}

