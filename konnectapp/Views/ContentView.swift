import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainView()
            } else if authManager.isLoading {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.06, blue: 0.06),
                            Color(red: 0.1, green: 0.1, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ProgressView()
                        .tint(Color(red: 0.82, green: 0.74, blue: 1.0))
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}
