import SwiftUI

struct ThemeSelectionModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackgroundStart,
                        Color.themeBackgroundEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Выбор темы")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.themeTextPrimary)
                            .padding(.top, 20)
                        
                        Text("Выберите цветовую схему приложения")
                            .font(.system(size: 16))
                            .foregroundColor(Color.themeTextSecondary)
                            .padding(.bottom, 20)
                        
                        VStack(spacing: 16) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                ThemeOptionRow(theme: theme, isSelected: themeManager.currentTheme == theme) {
                                    themeManager.currentTheme = theme
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
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
                    .foregroundColor(Color.themeTextPrimary)
                }
            }
        }
    }
}

struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(theme.previewColor)
                        .frame(width: 50, height: 50)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.themeTextPrimary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.themeTextPrimary)
                    
                    Text(themeDescription(theme))
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? theme.previewColor.opacity(0.2) : Color.themeBlockBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? theme.previewColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func themeDescription(_ theme: AppTheme) -> String {
        switch theme {
        case .purple: return "Стандартная тема приложения"
        case .darkGray: return "Классическая темная тема"
        case .amoled: return "Чистый черный с прозрачностью"
        case .blue: return "Свежая голубая палитра"
        case .green: return "Природная зеленая тема"
        }
    }
}

