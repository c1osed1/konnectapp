import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}
