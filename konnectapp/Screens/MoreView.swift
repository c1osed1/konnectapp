import SwiftUI

enum SearchType {
    case users
    case channels
}

class SearchTaskManager {
    private var currentTask: Task<Void, Never>?
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    func start(_ operation: @escaping () async -> Void) {
        cancel()
        currentTask = Task {
            await operation()
        }
    }
}

struct MoreView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationChecker = NotificationChecker.shared
    @ObservedObject private var accountManager = AccountSwitchManager.shared
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showNotifications = false
    @State private var isAccountsExpanded = false
    
    // Search state
    @State private var searchText: String = ""
    @State private var searchType: SearchType = .users
    @State private var searchUsers: [SearchUser] = []
    @State private var searchChannels: [SearchChannel] = []
    @State private var isSearching: Bool = false
    @State private var showSearchResults: Bool = false
    @FocusState private var isSearchFocused: Bool
    @Binding var navigationPath: NavigationPath
    
    @State private var searchTaskManager = SearchTaskManager()
    
    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: authManager.currentUser?.profile_background_url)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Search bar вместо текста "Еще"
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.themeTextSecondary)
                            .font(.system(size: 18))
                        
                        TextField("Поиск", text: $searchText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.themeTextPrimary)
                            .focused($isSearchFocused)
                            .onChange(of: searchText) { oldValue, newValue in
                                performSearch(query: newValue)
                            }
                            .onSubmit {
                                performSearch(query: searchText)
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                showSearchResults = false
                                searchUsers = []
                                searchChannels = []
                                isSearchFocused = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.themeTextSecondary)
                                    .font(.system(size: 18))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.themeBlockBackground)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                
                // ну шоб список красивый был скрываем все остальные кнопки
                if !showSearchResults {
                    // Список аккаунтов
                    if !accountManager.accounts.isEmpty || accountManager.mainAccount != nil {
                        VStack(spacing: 8) {
                            if let current = accountManager.currentAccount {
                                // Показываем только текущий аккаунт с кнопкой разворачивания
                                CompactAccountRow(
                                    account: current,
                                    isMain: current.account_type != "channel",
                                    isExpanded: isAccountsExpanded,
                                    onToggleExpand: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isAccountsExpanded.toggle()
                                        }
                                    }
                                )
                                
                                // Развернутый список всех аккаунтов
                                if isAccountsExpanded {
                                    if let main = accountManager.mainAccount, main.id != current.id {
                                        AccountRow(
                                            account: main,
                                            isCurrent: false,
                                            isMain: true,
                                            onSelect: { selectAccount(main) }
                                        )
                                    }
                                    
                                    ForEach(accountManager.accounts, id: \.id) { account in
                                        if account.id != current.id {
                                            AccountRow(
                                                account: account,
                                                isCurrent: false,
                                                isMain: false,
                                                onSelect: { selectAccount(account) }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    
                    Button {
                        showSettings = true
                    } label: {
                        MoreRow(icon: "gearshape.fill", title: "Настройки")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    
                    Button {
                        showNotifications = true
                    } label: {
                        MoreRow(icon: "bell.fill", title: "Уведомления", badgeCount: notificationChecker.unreadCount > 0 ? notificationChecker.unreadCount : nil)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    
                    Button {
                        showAbout = true
                    } label: {
                        MoreRow(icon: "info.circle", title: "О приложении")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                } else {
                    // Search results - показываем только когда есть результаты
                    searchResultsView
                }
                }
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    // Скрываем клавиатуру при тапе на ScrollView
                    isSearchFocused = false
                }
            )
        }
        .onTapGesture {
            // Скрываем клавиатуру при тапе вне поля поиска
            isSearchFocused = false
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsModalView()
        }
        .task {
            await loadUnreadCount()
        }
        .onChange(of: showNotifications) { oldValue, newValue in
            if !newValue {
                Task {
                    await loadUnreadCount()
                }
            }
        }
        .onAppear {
            accountManager.ensureLoaded()
        }
        .sheet(isPresented: $showAbout) {
            AboutAppView()
        }
    }
    
    private func selectAccount(_ account: User) {
        guard account.id != accountManager.currentAccount?.id else { return }
        Task {
            let success = await accountManager.switchAccount(accountId: account.id)
            if success {
                await authManager.checkAuthStatus()
            }
        }
    }
    
    private func loadUnreadCount() async {
        do {
            let response = try await NotificationService.shared.getNotifications()
            await MainActor.run {
                notificationChecker.unreadCount = response.unread_count ?? 0
            }
        } catch {
            print("❌ Error loading unread count: \(error)")
        }
    }
    
    // MARK: - Search
    private func performSearch(query: String) {
        // Отменяем предыдущий поиск
        searchTaskManager.cancel()
        
        guard query.count >= 2 else {
            showSearchResults = false
            searchUsers = []
            searchChannels = []
            return
        }
        
        searchTaskManager.start {
            try? await Task.sleep(nanoseconds: 500_000_000) // Задержка 0.5 секунды
            if !Task.isCancelled {
                await search(query: query)
            }
        }
    }
    
    private func search(query: String) async {
        await MainActor.run {
            isSearching = true
            showSearchResults = true
        }
        
        do {
            if searchType == .users {
                let response = try await SearchService.shared.searchUsers(query: query, perPage: 20)
                await MainActor.run {
                    searchUsers = response.users
                    isSearching = false
                }
            } else {
                let response = try await SearchService.shared.searchChannels(query: query, perPage: 20)
                await MainActor.run {
                    searchChannels = response.channels
                    isSearching = false
                }
            }
        } catch {
            await MainActor.run {
                isSearching = false
                print("❌ Error searching: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search type selector
            HStack(spacing: 0) {
                Button {
                    searchType = .users
                    if !searchText.isEmpty {
                        Task {
                            await search(query: searchText)
                        }
                    }
                } label: {
                    Text("Пользователи")
                        .font(.system(size: 16, weight: searchType == .users ? .semibold : .regular))
                        .foregroundColor(searchType == .users ? Color.themeTextPrimary : Color.themeTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(searchType == .users ? Color.themeBlockBackground : Color.clear)
                        )
                }
                
                Button {
                    searchType = .channels
                    if !searchText.isEmpty {
                        Task {
                            await search(query: searchText)
                        }
                    }
                } label: {
                    Text("Каналы")
                        .font(.system(size: 16, weight: searchType == .channels ? .semibold : .regular))
                        .foregroundColor(searchType == .channels ? Color.themeTextPrimary : Color.themeTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(searchType == .channels ? Color.themeBlockBackground : Color.clear)
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeBlockBackground.opacity(0.5))
            )
            .padding(.horizontal, 16)
            
            // Results
            if isSearching {
                ProgressView()
                    .tint(Color.themeTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if searchType == .users {
                if searchUsers.isEmpty {
                    Text("Пользователи не найдены")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(searchUsers) { user in
                            SearchUserRow(user: user, onTap: {
                                navigationPath.append(user.username)
                            }, onDismissKeyboard: {
                                isSearchFocused = false
                            })
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                if searchChannels.isEmpty {
                    Text("Каналы не найдены")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(searchChannels) { channel in
                            SearchChannelRow(channel: channel, onTap: {
                                navigationPath.append(channel.username)
                            }, onDismissKeyboard: {
                                isSearchFocused = false
                            })
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct SearchUserRow: View {
    let user: SearchUser
    let onTap: () -> Void
    let onDismissKeyboard: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            onDismissKeyboard()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Avatar
                if let avatarURL = URL(string: user.avatar_url ?? "") {
                    CachedAsyncImage(url: avatarURL, cacheType: .avatar)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent,
                                    Color(red: 0.75, green: 0.65, blue: 0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String((user.name ?? user.username).prefix(1)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(user.name ?? user.username)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                        
                        if user.is_verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                    
                    if let about = user.about, !about.isEmpty {
                        Text(about)
                            .font(.system(size: 13))
                            .foregroundColor(Color.themeTextSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.themeBlockBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchChannelRow: View {
    let channel: SearchChannel
    let onTap: () -> Void
    let onDismissKeyboard: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            onDismissKeyboard()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Avatar
                if let avatarURL = URL(string: channel.avatar_url ?? "") {
                    CachedAsyncImage(url: avatarURL, cacheType: .avatar)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent,
                                    Color(red: 0.75, green: 0.65, blue: 0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String((channel.name ?? channel.username).prefix(1)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(channel.name ?? channel.username)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                        
                        if channel.is_verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text("@\(channel.username)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                    
                    if let followersCount = channel.followers_count {
                        Text("\(followersCount) подписчиков")
                            .font(.system(size: 13))
                            .foregroundColor(Color.themeTextSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.themeBlockBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    let badgeCount: Int?
    
    init(icon: String, title: String, badgeCount: Int? = nil) {
        self.icon = icon
        self.title = title
        self.badgeCount = badgeCount
    }
    
    var body: some View {
        HStack {
            ZStack {
                Image(systemName: icon)
                    .foregroundColor(Color.appAccent)
                    .frame(width: 24)
                
                if let count = badgeCount, count > 0 {
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, count > 9 ? 4 : 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color.themeTextPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.themeTextSecondary)
                .font(.system(size: 14))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeBlockBackground)
        )
    }
}

