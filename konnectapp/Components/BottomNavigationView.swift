import SwiftUI

enum TabItem: String, CaseIterable {
    case feed = "Лента"
    case music = "Музыка"
    case profile = "Профиль"
    case more = "Еще"
    
    var icon: String {
        switch self {
        case .feed: return "house.fill"
        case .music: return "music.note"
        case .profile: return "person.fill"
        case .more: return "ellipsis"
        }
    }
}

struct BottomNavigationView: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        if #available(iOS 26.0, *) {
            liquidGlassNavigation
        } else {
            fallbackNavigation
        }
    }
    
    @available(iOS 26.0, *)
    private var liquidGlassNavigation: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.4))
                                    .frame(height: 36)
                                    .padding(.horizontal, 4)
                            }
                            
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                .frame(width: 26, height: 26)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 60)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 36))
        }
    }
    
    private var fallbackNavigation: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    ZStack {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.2))
                                .frame(height: 36)
                                .padding(.horizontal, 4)
                        }
                        
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                            .frame(width: 26, height: 26)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 36)
                    .fill(.ultraThinMaterial.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 36)
                    .stroke(
                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.2),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 8)
    }
}
