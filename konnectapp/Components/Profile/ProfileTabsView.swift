import SwiftUI

struct ProfileTabsView: View {
    @Binding var selectedTab: ProfileTabType
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                selectedTab = .posts
            } label: {
                Text("Посты")
                    .font(.system(size: 16, weight: selectedTab == .posts ? .semibold : .regular))
                    .foregroundColor(selectedTab == .posts ? Color.themeTextPrimary : Color.themeTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(selectedTab == .posts ? Color.themeBlockBackground : Color.clear)
                    )
            }
            
            Button {
                selectedTab = .wall
            } label: {
                Text("Стена")
                    .font(.system(size: 16, weight: selectedTab == .wall ? .semibold : .regular))
                    .foregroundColor(selectedTab == .wall ? Color.themeTextPrimary : Color.themeTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(selectedTab == .wall ? Color.themeBlockBackground : Color.clear)
                    )
            }
            
            Button {
                selectedTab = .about
            } label: {
                Text("Доп.Инфа")
                    .font(.system(size: 16, weight: selectedTab == .about ? .semibold : .regular))
                    .foregroundColor(selectedTab == .about ? Color.themeTextPrimary : Color.themeTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(selectedTab == .about ? Color.themeBlockBackground : Color.clear)
                    )
            }
        }
        .background(
            ZStack {
                // Более темный фоновый слой
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.themeBlockBackground.opacity(0.95))
                
                // Блюр эффект с затемнением
                RoundedRectangle(cornerRadius: 18)
                    .fill(.thinMaterial.opacity(0.3))
            }
        )
    }
}

