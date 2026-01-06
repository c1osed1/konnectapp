import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainView()
            } else if authManager.isLoading {
                ZStack {
                    AppBackgroundView(backgroundURL: authManager.currentUser?.profile_background_url)
                    
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
