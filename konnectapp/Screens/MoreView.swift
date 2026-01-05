import SwiftUI

struct MoreView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Еще")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 12) {
                    MoreRow(icon: "questionmark.circle", title: "Помощь")
                    MoreRow(icon: "info.circle", title: "О приложении")
                    MoreRow(icon: "doc.text", title: "Условия использования")
                    MoreRow(icon: "hand.raised", title: "Политика конфиденциальности")
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
}

struct MoreRow: View {
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

