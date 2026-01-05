import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var selectedTab: TabItem = .feed
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                
                TabContentView(selectedTab: $selectedTab, navigationPath: $navigationPath)
                    .overlay(alignment: .bottom) {
                        BottomNavigationView(selectedTab: $selectedTab)
                            .padding(.horizontal, 10)
                            .padding(.bottom, -20)
                            .opacity(keyboardObserver.isKeyboardVisible ? 0 : 1)
                            .animation(nil, value: keyboardObserver.isKeyboardVisible)
                    }
            }
            .navigationDestination(for: String.self) { username in
                UserProfileView(username: username)
            }
        }
    }
}

struct TabContentView: View {
    @Binding var selectedTab: TabItem
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        Group {
            switch selectedTab {
            case .feed:
                FeedView(navigationPath: $navigationPath)
            case .music:
                MusicView()
            case .profile:
                ProfileView()
            case .more:
                MoreView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

