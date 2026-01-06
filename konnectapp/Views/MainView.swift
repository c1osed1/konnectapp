import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var selectedTab: TabItem = .feed
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Фон должен быть позади всего контента и не влиять на layout
                AppBackgroundView(backgroundURL: authManager.currentUser?.profile_background_url)
                    .onAppear {
                        print("🟡 MainView: onAppear, currentUser: \(authManager.currentUser?.username ?? "nil")")
                        if let url = authManager.currentUser?.profile_background_url {
                            print("🟡 MainView: Using background URL: \(url)")
                        } else {
                            print("🔵 MainView: No background URL in currentUser")
                        }
                    }
                    .onChange(of: authManager.currentUser?.profile_background_url) { oldValue, newValue in
                        print("🔄 MainView: backgroundURL changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
                    }
                
                // Контент поверх фона
                TabContentView(selectedTab: $selectedTab, navigationPath: $navigationPath)
                    .overlay(alignment: .bottom) {
                        BottomNavigationView(selectedTab: $selectedTab)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 5)
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

