import SwiftUI
import Combine
import UIKit

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
    
    func colors(colorScheme: ColorScheme? = nil) -> ThemeColors {
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
                backgroundEnd: Color.black,
                blockBackground: Color.black,
                blockBackgroundSecondary: Color(red: 0.02, green: 0.02, blue: 0.02),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.8, green: 0.8, blue: 0.8),
                border: Color(red: 0.1, green: 0.1, blue: 0.1)
            )
        case .blue:
            return ThemeColors(
                accent: Color(red: 0.2, green: 0.6, blue: 1.0),
                backgroundStart: Color(red: 0.0, green: 0.05, blue: 0.15),
                backgroundEnd: Color(red: 0.0, green: 0.08, blue: 0.22),
                blockBackground: Color(red: 0.0, green: 0.1, blue: 0.25),
                blockBackgroundSecondary: Color(red: 0.0, green: 0.12, blue: 0.3),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.7, green: 0.8, blue: 0.9),
                border: Color(red: 0.0, green: 0.15, blue: 0.35)
            )
        case .purple:
            // Базовый: зависит от системной темы
            let isLight = colorScheme == .light
            if isLight {
                // Светлая тема - слегка темнее белого
                return ThemeColors(
                    accent: Color(red: 0.82, green: 0.74, blue: 1.0),
                    backgroundStart: Color(red: 0.96, green: 0.96, blue: 0.96),
                    backgroundEnd: Color(red: 0.94, green: 0.94, blue: 0.94),
                    blockBackground: Color(red: 0.98, green: 0.98, blue: 0.98),
                    blockBackgroundSecondary: Color(red: 0.95, green: 0.95, blue: 0.95),
                    textPrimary: Color.black,
                    textSecondary: Color(red: 0.3, green: 0.3, blue: 0.3),
                    border: Color(red: 0.85, green: 0.85, blue: 0.85)
                )
            } else {
                // Темная тема - серый (текущий)
                return ThemeColors(
                    accent: Color(red: 0.82, green: 0.74, blue: 1.0),
                    backgroundStart: Color(red: 0.06, green: 0.06, blue: 0.06),
                    backgroundEnd: Color(red: 0.08, green: 0.08, blue: 0.08),
                    blockBackground: Color(red: 0.1, green: 0.1, blue: 0.1),
                    blockBackgroundSecondary: Color(red: 0.12, green: 0.12, blue: 0.12),
                    textPrimary: Color.white,
                    textSecondary: Color(red: 0.7, green: 0.7, blue: 0.7),
                    border: Color(red: 0.15, green: 0.15, blue: 0.15)
                )
            }
        case .green:
            return ThemeColors(
                accent: Color(red: 0.2, green: 0.8, blue: 0.4),
                backgroundStart: Color(red: 0.0, green: 0.08, blue: 0.0),
                backgroundEnd: Color(red: 0.0, green: 0.12, blue: 0.0),
                blockBackground: Color(red: 0.0, green: 0.15, blue: 0.0),
                blockBackgroundSecondary: Color(red: 0.0, green: 0.2, blue: 0.0),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.7, green: 0.85, blue: 0.7),
                border: Color(red: 0.0, green: 0.3, blue: 0.0)
            )
        }
    }
    
    var colors: ThemeColors {
        // Для обратной совместимости, используем темную тему по умолчанию
        return colors(colorScheme: nil)
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
    
    @Published var isGlassEffectEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGlassEffectEnabled, forKey: "glassEffectEnabled")
        }
    }
    
    @Published var systemColorScheme: ColorScheme = .dark {
        didSet {
            // Обновляем цвета при изменении системной темы для базовой темы
            if currentTheme == .purple {
                objectWillChange.send()
            }
        }
    }
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .purple
        }
        
        // По умолчанию glass эффект включен
        self.isGlassEffectEnabled = UserDefaults.standard.object(forKey: "glassEffectEnabled") as? Bool ?? true
        
        // Определяем системную тему при инициализации
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let traitCollection = window.traitCollection
            self.systemColorScheme = traitCollection.userInterfaceStyle == .light ? .light : .dark
        }
    }
    
    func updateSystemColorScheme(_ colorScheme: ColorScheme) {
        systemColorScheme = colorScheme
    }
    
    var effectiveColors: ThemeColors {
        if currentTheme == .purple {
            return currentTheme.colors(colorScheme: systemColorScheme)
        }
        return currentTheme.colors
    }
}

