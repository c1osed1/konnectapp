import SwiftUI

enum TabItem: String {
    case feed
    case music
    case chats
    case profile
    case more
}

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var keyboardObserver = KeyboardObserver()
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationChecker = NotificationChecker.shared
    @State private var selectedTab: TabItem = .feed
    @State private var navigationPath = NavigationPath()
    @State private var showPostDetail: Post?
    @State private var showTrack: Int64?
    
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
                        
                        // Connect WebSocket immediately when MainView appears
                        MessengerWebSocketService.shared.connect()
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
                    
                    ChatsView()
                        .tag(TabItem.chats)
                        .tabItem {
                            Label("Чаты", systemImage: "message.fill")
                        }
                    
                    ProfileView()
                        .tag(TabItem.profile)
                        .tabItem {
                            Label("Профиль", systemImage: "person.fill")
                        }
                    
                    Group {
                        if notificationChecker.unreadCount > 0 {
                            MoreView()
                                .tag(TabItem.more)
                                .tabItem {
                                    Label("Еще", systemImage: "ellipsis")
                                }
                                .badge(notificationChecker.unreadCount)
                        } else {
                            MoreView()
                                .tag(TabItem.more)
                                .tabItem {
                                    Label("Еще", systemImage: "ellipsis")
                                }
                        }
                    }
                }
                .accentColor(Color.appAccent)
            }
            .navigationDestination(for: String.self) { username in
                UserProfileView(username: username)
            }
            .navigationDestination(for: Chat.self) { chat in
                ChatView(chat: chat)
            }
            .sheet(item: Binding(
                get: { showPostDetail },
                set: { showPostDetail = $0 }
            )) { post in
                PostDetailView(post: post, navigationPath: $navigationPath)
            }
            .fullScreenCover(isPresented: Binding(
                get: { showTrack != nil },
                set: { if !$0 { showTrack = nil } }
            )) {
                FullScreenPlayerView()
            }
            .onChange(of: deepLinkHandler.targetUsername) { oldValue, newValue in
                if let username = newValue {
                    selectedTab = .feed
                    navigationPath.append(username)
                    deepLinkHandler.targetUsername = nil
                }
            }
            .onChange(of: deepLinkHandler.targetPostId) { oldValue, newValue in
                if let postId = newValue {
                    Task {
                        await loadPostById(postId)
                    }
                    deepLinkHandler.targetPostId = nil
                }
            }
            .onChange(of: deepLinkHandler.targetTrackId) { oldValue, newValue in
                if let trackId = newValue {
                    Task {
                        await loadTrackById(trackId)
                    }
                    deepLinkHandler.targetTrackId = nil
                }
            }
            .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
                if newValue {
                    notificationChecker.startChecking()
                } else {
                    notificationChecker.stopChecking()
                }
            }
            .onAppear {
                if authManager.isAuthenticated {
                    notificationChecker.startChecking()
                }
            }
            .onDisappear {
                notificationChecker.stopChecking()
            }
        }
    }
    
    private func loadPostById(_ postId: Int64) async {
        do {
            let response = try await CommentService.shared.getPostDetail(postId: postId, includeComments: false)
            if let post = response.post {
                await MainActor.run {
                    selectedTab = .feed
                    showPostDetail = post
                }
            }
        } catch {
            print("❌ Error loading post: \(error)")
        }
    }
    
    private func loadTrackById(_ trackId: Int64) async {
        do {
            let response = try await MusicService.shared.getTrack(trackId: trackId)
            let track = response.track
            let musicTrack = MusicTrack(
                id: track.id,
                title: track.title,
                artist: track.artist,
                album: track.album,
                cover_path: track.cover_path,
                file_path: track.file_path,
                duration: track.duration,
                genre: track.genre,
                is_liked: nil,
                likes_count: track.likes_count,
                plays_count: track.plays_count,
                user_id: track.user_id,
                user_name: track.user_name,
                user_username: track.user_username,
                verified: track.verified,
                created_at: track.created_at,
                description: track.description,
                artist_id: track.artist_id,
                trend: nil,
                trend_data: nil
            )
            await MainActor.run {
                selectedTab = .music
                MusicPlayer.shared.playTrack(musicTrack)
                showTrack = trackId
            }
        } catch {
            print("❌ Error loading track: \(error)")
        }
    }
}

