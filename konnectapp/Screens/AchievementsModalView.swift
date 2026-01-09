import SwiftUI

struct AchievementsModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var achievements: [UserAchievement] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isActivating = false
    @State private var activeAchievementId: Int64?
    
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
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(Color.themeTextPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Активный бейдж (только SVG)
                            if let activeAchievement = achievements.first(where: { $0.is_active && $0.is_active_badge && !$0.image_path.lowercased().hasSuffix(".gif") }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Активный бейдж")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.themeTextPrimary)
                                        .padding(.horizontal, 16)
                                    
                                    AchievementRow(
                                        achievement: activeAchievement,
                                        isActive: true,
                                        onActivate: nil,
                                        onDeactivate: {
                                            Task {
                                                await deactivateAchievement()
                                            }
                                        },
                                        isActivating: isActivating && activeAchievementId == activeAchievement.id
                                    )
                                    .padding(.horizontal, 16)
                                }
                                .padding(.top, 20)
                            }
                            
                            // Все бейджи (только SVG)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Все бейджи")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.themeTextPrimary)
                                    .padding(.horizontal, 16)
                                
                                ForEach(achievements.filter { achievement in
                                    let isNotActive = !achievement.is_active || !achievement.is_active_badge
                                    let isNotGIF = !achievement.image_path.lowercased().hasSuffix(".gif")
                                    return isNotActive && isNotGIF
                                }) { achievement in
                                    AchievementRow(
                                        achievement: achievement,
                                        isActive: false,
                                        onActivate: {
                                            Task {
                                                await activateAchievement(achievementId: achievement.id)
                                            }
                                        },
                                        onDeactivate: nil,
                                        isActivating: isActivating && activeAchievementId == achievement.id
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, achievements.first(where: { $0.is_active && $0.is_active_badge && !$0.image_path.lowercased().hasSuffix(".gif") }) != nil ? 20 : 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Бейджи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(Color.themeTextPrimary)
                }
            }
            .task {
                await loadAchievements()
            }
        }
    }
    
    private func loadAchievements() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await AchievementService.shared.getAchievements()
            await MainActor.run {
                self.achievements = response.achievements
                self.activeAchievementId = response.achievements.first(where: { $0.is_active && $0.is_active_badge })?.id
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка загрузки бейджей: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func activateAchievement(achievementId: Int64) async {
        guard !isActivating else { return }
        
        await MainActor.run {
            isActivating = true
            activeAchievementId = achievementId
        }
        
        do {
            let response = try await AchievementService.shared.activateAchievement(achievementId: achievementId)
            if response.success {
                ToastHelper.showToast(message: response.message ?? "Бейдж активирован")
                await loadAchievements()
            }
        } catch {
            await MainActor.run {
                ToastHelper.showToast(message: "Ошибка активации: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isActivating = false
            activeAchievementId = nil
        }
    }
    
    private func deactivateAchievement() async {
        guard !isActivating else { return }
        
        await MainActor.run {
            isActivating = true
        }
        
        do {
            let response = try await AchievementService.shared.deactivateAchievement()
            if response.success {
                ToastHelper.showToast(message: response.message ?? "Бейдж деактивирован")
                await loadAchievements()
            }
        } catch {
            await MainActor.run {
                ToastHelper.showToast(message: "Ошибка деактивации: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isActivating = false
            activeAchievementId = nil
        }
    }
}

struct AchievementRow: View {
    let achievement: UserAchievement
    let isActive: Bool
    let onActivate: (() -> Void)?
    let onDeactivate: (() -> Void)?
    let isActivating: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Бейдж
            AchievementBadgeView(imagePath: achievement.image_path, size: 50)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.bage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.themeTextPrimary)
                    .lineLimit(1)
                
                if let dateAwarded = achievement.date_awarded {
                    Text(DateFormatterHelper.formatRelativeTime(dateAwarded))
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isActive {
                if let onDeactivate = onDeactivate {
                    Button(action: onDeactivate) {
                        Text("Снять")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                    .disabled(isActivating)
                }
            } else {
                if let onActivate = onActivate {
                    Button(action: onActivate) {
                        if isActivating {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Text("Надеть")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.themeTextPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appAccent.opacity(0.2))
                                )
                        }
                    }
                    .disabled(isActivating)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isActive ? Color.appAccent.opacity(0.15) : Color.themeBlockBackground)
        )
    }
    
}
