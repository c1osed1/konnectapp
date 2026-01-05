import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var selectedTab: TabItem = .feed
    
    var body: some View {
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
            
            TabContentView(selectedTab: $selectedTab)
                .overlay(alignment: .bottom) {
                    BottomNavigationView(selectedTab: $selectedTab)
                        .padding(.horizontal, 10)
                        .padding(.bottom, -20)
                        .opacity(keyboardObserver.isKeyboardVisible ? 0 : 1)
                        .animation(nil, value: keyboardObserver.isKeyboardVisible)
                }
        }
    }
}

struct TabContentView: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        Group {
            switch selectedTab {
            case .feed:
                FeedView()
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

