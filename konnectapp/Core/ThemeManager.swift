import SwiftUI
import Combine

struct ThemeColors {
    let accent: Color
    let backgroundStart: Color
    let backgroundEnd: Color
    let blockBackground: Color
    let blockBackgroundSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let border: Color
}

enum AppTheme: String, CaseIterable, Codable {
    case purple = "purple"
    case darkGray = "darkGray"
    case amoled = "amoled"
    case blue = "blue"
    case green = "green"
    
    var name: String {
        switch self {
        case .purple: return "Базовый"
        case .darkGray: return "Темно-серый"
        case .amoled: return "Амолед"
        case .blue: return "Голубой"
        case .green: return "Зеленый"
        }
    }
    
    var colors: ThemeColors {
        switch self {
        case .darkGray:
            return ThemeColors(
                accent: Color(red: 0.6, green: 0.6, blue: 0.6),
                backgroundStart: Color(red: 0.08, green: 0.08, blue: 0.08),
                backgroundEnd: Color(red: 0.12, green: 0.12, blue: 0.12),
                blockBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
                blockBackgroundSecondary: Color(red: 0.18, green: 0.18, blue: 0.18),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.7, green: 0.7, blue: 0.7),
                border: Color(red: 0.25, green: 0.25, blue: 0.25)
            )
        case .amoled:
            return ThemeColors(
                accent: Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.9),
                backgroundStart: Color.black,
                backgroundEnd: Color(red: 0.02, green: 0.02, blue: 0.02),
                blockBackground: Color(red: 0.05, green: 0.05, blue: 0.05),
                blockBackgroundSecondary: Color(red: 0.08, green: 0.08, blue: 0.08),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.8, green: 0.8, blue: 0.8),
                border: Color(red: 0.15, green: 0.15, blue: 0.15)
            )
        case .blue:
            return ThemeColors(
                accent: Color(red: 0.2, green: 0.6, blue: 1.0),
                backgroundStart: Color(red: 0.05, green: 0.1, blue: 0.15),
                backgroundEnd: Color(red: 0.08, green: 0.15, blue: 0.22),
                blockBackground: Color(red: 0.1, green: 0.15, blue: 0.2),
                blockBackgroundSecondary: Color(red: 0.12, green: 0.18, blue: 0.25),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.7, green: 0.8, blue: 0.9),
                border: Color(red: 0.15, green: 0.2, blue: 0.3)
            )
        case .purple:
            return ThemeColors(
                accent: Color(red: 0.82, green: 0.74, blue: 1.0),
                backgroundStart: Color(red: 0.06, green: 0.06, blue: 0.06),
                backgroundEnd: Color(red: 0.1, green: 0.1, blue: 0.1),
                blockBackground: Color(red: 0.13, green: 0.13, blue: 0.13),
                blockBackgroundSecondary: Color(red: 0.16, green: 0.16, blue: 0.16),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.7, green: 0.7, blue: 0.7),
                border: Color(red: 0.2, green: 0.2, blue: 0.2)
            )
        case .green:
            return ThemeColors(
                accent: Color(red: 0.2, green: 0.8, blue: 0.4),
                backgroundStart: Color(red: 0.05, green: 0.1, blue: 0.05),
                backgroundEnd: Color(red: 0.08, green: 0.15, blue: 0.08),
                blockBackground: Color(red: 0.1, green: 0.15, blue: 0.1),
                blockBackgroundSecondary: Color(red: 0.12, green: 0.18, blue: 0.12),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.7, green: 0.85, blue: 0.7),
                border: Color(red: 0.15, green: 0.25, blue: 0.15)
            )
        }
    }
    
    var accentColor: Color {
        return colors.accent
    }
    
    var previewColor: Color {
        return accentColor
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .purple
        }
    }
}

