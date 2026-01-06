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
                
                // Базовый TabView из SwiftUI
                TabView(selection: $selectedTab) {
                    FeedView(navigationPath: $navigationPath)
                        .tag(TabItem.feed)
                        .tabItem {
                            Label("Лента", systemImage: "house.fill")
                        }
                    
                    MusicView()
                        .tag(TabItem.music)
                        .tabItem {
                            Label("Музыка", systemImage: "music.note")
                        }
                    
                    ProfileView()
                        .tag(TabItem.profile)
                        .tabItem {
                            Label("Профиль", systemImage: "person.fill")
                        }
                    
                    MoreView()
                        .tag(TabItem.more)
                        .tabItem {
                            Label("Еще", systemImage: "ellipsis")
                        }
                }
                .accentColor(Color.appAccent)
            }
            .navigationDestination(for: String.self) { username in
                UserProfileView(username: username)
            }
        }
    }
}

