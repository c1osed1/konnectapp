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
        return Color.accentColor(from: AuthManager.shared.currentUser)
    }
}

