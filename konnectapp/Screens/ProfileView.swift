import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let user = authManager.currentUser {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.82, green: 0.74, blue: 1.0),
                                        Color(red: 0.75, green: 0.65, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(user.name.prefix(1)))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.black)
                            )
                        
                        Text(user.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("@\(user.username)")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                    }
                    .padding(.top, 40)
                }
                
                VStack(spacing: 12) {
                    ProfileRow(icon: "person.circle", title: "Редактировать профиль")
                    ProfileRow(icon: "bell", title: "Уведомления")
                    ProfileRow(icon: "lock", title: "Безопасность")
                    ProfileRow(icon: "gear", title: "Настройки")
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .padding(.bottom, 100)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
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

