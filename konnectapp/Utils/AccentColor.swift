import SwiftUI

extension Color {
    /// Получает акцентный цвет из профиля пользователя или возвращает дефолтный розовый
    static func accentColor(from user: User?) -> Color {
        if let profileColor = user?.profile_color,
           let color = Color(hex: profileColor) {
            return color
        }
        // Дефолтный розовый цвет
        return Color.appAccent
    }
    
    /// Получает акцентный цвет из ProfileUser или возвращает дефолтный розовый
    static func accentColor(from profileUser: ProfileUser?) -> Color {
        if let profileColor = profileUser?.profile_color,
           let color = Color(hex: profileColor) {
            return color
        }
        // Дефолтный розовый цвет
        return Color.appAccent
    }
    
    /// Глобальный акцентный цвет из текущего пользователя
    static var appAccent: Color {
        return Color.accentColor(from: AuthManager.shared.currentUser)
    }
}

