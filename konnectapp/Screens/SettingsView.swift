import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showBackgroundModal = false
    @State private var showCacheModal = false
    @State private var showThemeModal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView(backgroundURL: authManager.currentUser?.profile_background_url)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Настройки")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Внешний вид")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        
                        Button {
                            showThemeModal = true
                        } label: {
                            MoreRow(icon: "paintpalette.fill", title: "Тема оформления")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Профиль")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        
                        Button {
                            showBackgroundModal = true
                        } label: {
                            MoreRow(icon: "photo.fill", title: "Фон профиля")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Кеш")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        
                        Button {
                            showCacheModal = true
                        } label: {
                            MoreRow(icon: "internaldrive", title: "Управление кешем")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showBackgroundModal) {
                ProfileBackgroundModalView()
            }
            .sheet(isPresented: $showCacheModal) {
                CacheSettingsModalView()
            }
            .sheet(isPresented: $showThemeModal) {
                ThemeSelectionModalView()
            }
        }
    }
}

