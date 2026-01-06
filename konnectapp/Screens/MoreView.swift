import SwiftUI

struct MoreView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationChecker = NotificationChecker.shared
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showNotifications = false
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: authManager.currentUser?.profile_background_url)
            
            ScrollView {
                VStack(spacing: 20) {
                Text("Еще")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Button {
                    showSettings = true
                } label: {
                    MoreRow(icon: "gearshape.fill", title: "Настройки")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                
                Button {
                    showNotifications = true
                } label: {
                    MoreRow(icon: "bell.fill", title: "Уведомления", badgeCount: notificationChecker.unreadCount > 0 ? notificationChecker.unreadCount : nil)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                
                Button {
                    showAbout = true
                } label: {
                    MoreRow(icon: "info.circle", title: "О приложении")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                
                Button(action: {
                    Task {
                        try? await authManager.logout()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Выйти")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.96, green: 0.26, blue: 0.21))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                }
                .padding(.bottom, 100)
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsModalView()
        }
        .task {
            await loadUnreadCount()
        }
        .onChange(of: showNotifications) { isPresented in
            if !isPresented {
                Task {
                    await loadUnreadCount()
                }
            }
        }
        .onAppear {
            Task {
                await loadUnreadCount()
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutAppView()
        }
    }
    
    private func loadUnreadCount() async {
        do {
            let response = try await NotificationService.shared.getNotifications()
            await MainActor.run {
                notificationChecker.unreadCount = response.unread_count ?? 0
            }
        } catch {
            print("❌ Error loading unread count: \(error)")
        }
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    let badgeCount: Int?
    
    init(icon: String, title: String, badgeCount: Int? = nil) {
        self.icon = icon
        self.title = title
        self.badgeCount = badgeCount
    }
    
    var body: some View {
        HStack {
            ZStack {
                Image(systemName: icon)
                    .foregroundColor(Color.appAccent)
                    .frame(width: 24)
                
                if let count = badgeCount, count > 0 {
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, count > 9 ? 4 : 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.themeTextSecondary)
                .font(.system(size: 14))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeBlockBackground)
        )
    }
}

