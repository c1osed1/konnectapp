import SwiftUI

struct ProfileAboutContent: View {
    let profile: ProfileUser
    let socials: [Social]?
    let isPrivate: Bool?
    let isFriend: Bool?
    let isOwnProfile: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if let isPrivate = isPrivate, isPrivate && !isOwnProfile && !(isFriend ?? false) {
                // Приватный профиль
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    Text("Приватный профиль")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                    Text("Подпишитесь друг на друга для просмотра информации")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 16)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                        // Текст "О себе"
                        if let about = profile.about, !about.isEmpty {
                            aboutSection(about: about)
                        }
                        
                        // Интересы - скрыто
                        // if let interests = profile.interests, !interests.isEmpty {
                        //     interestsSection(interests: interests)
                        // }
                        
                        // Купленные юзернеймы
                        if let purchasedUsernames = profile.purchased_usernames, !purchasedUsernames.isEmpty {
                            purchasedUsernamesSection(usernames: purchasedUsernames)
                        }
                        
                        // Дата регистрации
                        if let registrationDate = profile.registration_date {
                            registrationDateSection(date: registrationDate)
                        }
                        
                        // Социальные сети
                        if let socials = socials, !socials.isEmpty {
                            socialsSection(socials: socials)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
    }
    
    @ViewBuilder
    private func aboutSection(about: String) -> some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassAboutSection(about: about)
            } else {
                fallbackAboutSection(about: about)
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassAboutSection(about: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("О себе")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(about)
                .font(.system(size: 14))
                .foregroundColor(Color.themeTextPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func fallbackAboutSection(about: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("О себе")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(about)
                .font(.system(size: 14))
                .foregroundColor(Color.themeTextPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
    
    @ViewBuilder
    private func interestsSection(interests: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Интересы")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            FlowLayout(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.appAccent.opacity(0.2))
                        )
                }
            }
        }
        .padding(16)
        .background(
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 16)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.themeBlockBackground.opacity(0.9))
                }
            }
        )
    }
    
    @ViewBuilder
    private func purchasedUsernamesSection(usernames: [PurchasedUsername]) -> some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassPurchasedUsernamesSection(usernames: usernames)
            } else {
                fallbackPurchasedUsernamesSection(usernames: usernames)
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassPurchasedUsernamesSection(usernames: [PurchasedUsername]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "at")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("Купленные юзернеймы")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(usernames, id: \.id) { username in
                    HStack(spacing: 4) {
                        Text("@\(username.username)")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        if username.is_active {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(username.is_active ? Color.appAccent.opacity(0.3) : Color.appAccent.opacity(0.2))
                    )
                }
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func fallbackPurchasedUsernamesSection(usernames: [PurchasedUsername]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "at")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("Купленные юзернеймы")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(usernames, id: \.id) { username in
                    HStack(spacing: 4) {
                        Text("@\(username.username)")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        if username.is_active {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(username.is_active ? Color.appAccent.opacity(0.3) : Color.appAccent.opacity(0.2))
                    )
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
    
    @ViewBuilder
    private func registrationDateSection(date: String) -> some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassRegistrationDateSection(date: date)
            } else {
                fallbackRegistrationDateSection(date: date)
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassRegistrationDateSection(date: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Дата регистрации")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(formatDate(date) ?? date)
                    .font(.system(size: 13))
                    .foregroundColor(Color.themeTextSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func fallbackRegistrationDateSection(date: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Дата регистрации")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(formatDate(date) ?? date)
                    .font(.system(size: 13))
                    .foregroundColor(Color.themeTextSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
    
    @ViewBuilder
    private func socialsSection(socials: [Social]) -> some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassSocialsSection(socials: socials)
            } else {
                fallbackSocialsSection(socials: socials)
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassSocialsSection(socials: [Social]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Социальные сети")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(socials, id: \.name) { social in
                if let url = URL(string: social.link) {
                    Link(destination: url) {
                        HStack(spacing: 12) {
                            // Используем цвет из названия соцсети или дефолтный
                            let socialColor = getSocialColor(social.name)
                            Circle()
                                .fill(socialColor)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(social.name.prefix(1).uppercased()))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(social.name)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(12)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func fallbackSocialsSection(socials: [Social]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Социальные сети")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(socials, id: \.name) { social in
                if let url = URL(string: social.link) {
                    Link(destination: url) {
                        HStack(spacing: 12) {
                            // Используем цвет из названия соцсети или дефолтный
                            let socialColor = getSocialColor(social.name)
                            Circle()
                                .fill(socialColor)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(social.name.prefix(1).uppercased()))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(social.name)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.3))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.themeBlockBackground.opacity(0.9))
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
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
            }
        )
    }
    
    private func formatDate(_ dateString: String) -> String? {
        // Пробуем разные форматы ISO8601
        let formatters: [ISO8601DateFormatter] = [
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime]
                return f
            }(),
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                return f
            }(),
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withFullDate]
                return f
            }()
        ]
        
        // Создаем локализованный форматтер один раз
        let createDisplayFormatter: () -> DateFormatter = {
            let formatter = DateFormatter()
            // Пробуем использовать русскую локаль, если доступна
            if Locale.availableIdentifiers.contains("ru_RU") {
                formatter.locale = Locale(identifier: "ru_RU")
            } else {
                formatter.locale = Locale.current
            }
            formatter.dateFormat = "d MMMM yyyy"
            return formatter
        }
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                let displayFormatter = createDisplayFormatter()
                return displayFormatter.string(from: date)
            }
        }
        
        // Пробуем стандартный DateFormatter как последний вариант
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = standardFormatter.date(from: dateString) {
            let displayFormatter = createDisplayFormatter()
            return displayFormatter.string(from: date)
        }
        
        // Если ничего не помогло, пробуем просто дату без времени
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateOnlyFormatter.date(from: dateString) {
            let displayFormatter = createDisplayFormatter()
            return displayFormatter.string(from: date)
        }
        
        return nil
    }
    
    private func getSocialColor(_ name: String) -> Color {
        let lowercased = name.lowercased()
        switch lowercased {
        case "instagram":
            return Color(hex: "#E4405F") ?? .pink
        case "vk", "vkontakte":
            return Color(hex: "#0077FF") ?? .blue
        case "facebook":
            return Color(hex: "#1877F2") ?? .blue
        case "twitter", "x":
            return Color(hex: "#1DA1F2") ?? .blue
        case "youtube":
            return Color(hex: "#FF0000") ?? .red
        case "telegram":
            return Color(hex: "#0088CC") ?? .blue
        case "element":
            return Color(hex: "#0DBD8B") ?? .green
        default:
            return Color.appAccent
        }
    }
}

// Простой FlowLayout для отображения чипсов
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var frames: [CGRect] = []
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.frames = frames
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

