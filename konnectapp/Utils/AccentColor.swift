import SwiftUI

extension Color {
    private static let defaultAccentColor = Color(red: 0.82, green: 0.74, blue: 1.0)
    
    static func accentColor(from user: User?) -> Color {
        if let profileColor = user?.profile_color,
           let color = Color(hex: profileColor) {
            return color
        }
        return defaultAccentColor
    }
    
    static func accentColor(from profileUser: ProfileUser?) -> Color {
        if let profileColor = profileUser?.profile_color,
           let color = Color(hex: profileColor) {
            return color
        }
        return defaultAccentColor
    }
    
    static var appAccent: Color {
        if let currentUser = AuthManager.shared.currentUser {
            return accentColor(from: currentUser)
        }
        return defaultAccentColor
    }
    
    static var themeBackgroundStart: Color {
        return ThemeManager.shared.currentTheme.colors.backgroundStart
    }
    
    static var themeBackgroundEnd: Color {
        return ThemeManager.shared.currentTheme.colors.backgroundEnd
    }
    
    static var themeBlockBackground: Color {
        return ThemeManager.shared.currentTheme.colors.blockBackground
    }
    
    static var themeBlockBackgroundSecondary: Color {
        return ThemeManager.shared.currentTheme.colors.blockBackgroundSecondary
    }
    
    static var themeTextPrimary: Color {
        return ThemeManager.shared.currentTheme.colors.textPrimary
    }
    
    static var themeTextSecondary: Color {
        return ThemeManager.shared.currentTheme.colors.textSecondary
    }
    
    static var themeBorder: Color {
        return ThemeManager.shared.currentTheme.colors.border
    }
}

