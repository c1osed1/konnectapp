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
                        .tint(Color.appAccent)
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
