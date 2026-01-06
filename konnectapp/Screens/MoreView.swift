import SwiftUI

struct MoreView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showBackgroundModal = false
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: authManager.currentUser?.profile_background_url)
            
            ScrollView {
                VStack(spacing: 20) {
                Text("Еще")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Настройки
                VStack(alignment: .leading, spacing: 12) {
                    Text("Настройки")
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
                
                VStack(spacing: 12) {
                    MoreRow(icon: "info.circle", title: "О приложении")
                }
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
        .sheet(isPresented: $showBackgroundModal) {
            ProfileBackgroundModalView()
        }
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.appAccent)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                .font(.system(size: 14))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
        )
    }
}

