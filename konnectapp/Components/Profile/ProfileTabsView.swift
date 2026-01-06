import SwiftUI

struct ProfileTabsView: View {
    @Binding var selectedTab: ProfileTabType
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                Picker("", selection: $selectedTab) {
                    Text("Посты").tag(ProfileTabType.posts)
                    Text("Стена").tag(ProfileTabType.wall)
                    Text("Доп.Инфа").tag(ProfileTabType.about)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .font(.system(size: 16, weight: .medium))
                .frame(height: 48)
                .glassEffect(in: RoundedRectangle(cornerRadius: 24))
            } else {
                Picker("", selection: $selectedTab) {
                    Text("Посты").tag(ProfileTabType.posts)
                    Text("Стена").tag(ProfileTabType.wall)
                    Text("Доп.Инфа").tag(ProfileTabType.about)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .font(.system(size: 16, weight: .medium))
                .frame(height: 48)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.themeBlockBackground.opacity(0.9))
                            )
                        
                        RoundedRectangle(cornerRadius: 8)
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

