import SwiftUI

struct MusicView: View {
    @StateObject private var viewModel = MusicViewModel()
    @StateObject private var player = MusicPlayer.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab: MusicMainTab = .general
    @State private var showFullScreenPlayer: Bool = false
    
    var body: some View {
        ZStack {
            AppBackgroundView(backgroundURL: AuthManager.shared.currentUser?.profile_background_url)
            
            VStack(spacing: 0) {
                // Блок "Мой Вайб" сверху
                myVibeBlock
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Стандартные iOS табы
                Group {
                    if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                        Picker("", selection: $selectedTab) {
                            Text("Общее").tag(MusicMainTab.general)
                            Text("Любимые").tag(MusicMainTab.liked)
                            Text("Поиск").tag(MusicMainTab.search)
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.large)
                        .font(.system(size: 16, weight: .medium))
                        .frame(height: 48)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 24))
                    } else {
                        Picker("", selection: $selectedTab) {
                            Text("Общее").tag(MusicMainTab.general)
                            Text("Любимые").tag(MusicMainTab.liked)
                            Text("Поиск").tag(MusicMainTab.search)
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.large)
                        .font(.system(size: 16, weight: .medium))
                        .frame(height: 48)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial.opacity(0.3))
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.themeBlockBackground.opacity(0.9))
                                    )
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        Color.appAccent.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Контент
                Group {
                    if selectedTab == .general {
                        generalContent
                    } else if selectedTab == .liked {
                        likedContent
                    } else {
                        searchContent
                    }
                }
            }
            
            // Мини-плеер внизу
            if let currentTrack = player.currentTrack {
                miniPlayerView(track: currentTrack)
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPlayer) {
            FullScreenPlayerView()
        }
        .task {
            if viewModel.myVibeTracks.isEmpty {
                await viewModel.loadMyVibe()
            }
            if viewModel.charts == nil {
                await viewModel.loadCharts(type: .popular)
            }
            if viewModel.recentTracks.isEmpty {
                await viewModel.loadRecentTracks(type: .all)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .liked && viewModel.likedTracks.isEmpty {
                Task {
                    await viewModel.loadLikedTracks()
                }
            }
        }
    }
    
    // MARK: - My Vibe Block
    private var myVibeBlock: some View {
        Button(action: {
            // Начинаем воспроизведение "Мой Вайб"
            if !viewModel.myVibeTracks.isEmpty {
                player.setPlaylist(viewModel.myVibeTracks, startIndex: 0)
            }
        }) {
            HStack(spacing: 16) {
                // Градиентная обложка
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.8),
                                    Color.appAccent.opacity(0.4),
                                    Color(red: 0.75, green: 0.65, blue: 0.95).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    // Иконка волны
                    Image(systemName: "waveform")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(Color.themeTextPrimary.opacity(0.9))
                        .symbolEffect(.pulse)
                }
                .shadow(color: Color.appAccent.opacity(0.5), radius: 20, x: 0, y: 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Мой Вайб")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.themeTextPrimary)
                    
                    if viewModel.isLoadingMyVibe {
                        Text("Загрузка...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.themeTextSecondary)
                    } else if viewModel.myVibeTracks.isEmpty {
                        Text("Лайкайте треки для рекомендаций")
                            .font(.system(size: 14))
                            .foregroundColor(Color.themeTextSecondary)
                    } else {
                        Text("\(viewModel.myVibeTracks.count) треков")
                            .font(.system(size: 14))
                            .foregroundColor(Color.themeTextSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.appAccent)
                        Text("Начать")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.appAccent)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                Group {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.themeBlockBackground.opacity(0.6))
                            )
                            .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 24))
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.themeBlockBackground.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - General Content
    private var generalContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Блок "Чарты"
                chartsBlock
                    .padding(.bottom, 24)
                
                // Блок "Последнее"
                recentBlock
            }
            .padding(.bottom, player.currentTrack != nil ? 100 : 20)
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.loadCharts(type: viewModel.selectedChartType)
                }
                group.addTask {
                    await viewModel.loadRecentTracks(type: viewModel.selectedTrackListType, offset: 0)
                }
            }
        }
    }
    
    // MARK: - Charts Block
    private var chartsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Чарты")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.themeTextPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // Табы для выбора типа чарта
            chartTypeSelector
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            
            if viewModel.isLoadingCharts {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if let charts = viewModel.charts {
                // Отображаем выбранный тип чарта на всю ширину
                chartsContentView(charts: charts)
            }
        }
    }
    
    @ViewBuilder
    private func chartsContentView(charts: ChartsData) -> some View {
        let tracks: [MusicTrack] = {
            switch viewModel.selectedChartType {
            case .popular:
                return charts.popular ?? []
            case .plays:
                return charts.most_played ?? []
            case .likes:
                return charts.most_liked ?? []
            case .new:
                return charts.new_releases ?? []
            case .combined:
                return []
            }
        }()
        
        if tracks.isEmpty {
            emptyStateView(
                icon: "chart.bar",
                title: "Чарты пусты",
                message: "Попробуйте позже"
            )
        } else {
            LazyVStack(spacing: 4) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    chartTrackRow(track: track, position: index + 1, playlist: tracks)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
    
    private var chartTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ChartTypeButton(title: "Популярный", type: .popular, selected: $viewModel.selectedChartType)
                ChartTypeButton(title: "Прослушивания", type: .plays, selected: $viewModel.selectedChartType)
                ChartTypeButton(title: "Лайки", type: .likes, selected: $viewModel.selectedChartType)
                ChartTypeButton(title: "Новинки", type: .new, selected: $viewModel.selectedChartType)
            }
            .padding(.horizontal, 4)
        }
        .onChange(of: viewModel.selectedChartType) { oldValue, newValue in
            Task {
                await viewModel.loadCharts(type: newValue)
            }
        }
    }
    
    private func chartTrackRow(track: MusicTrack, position: Int, playlist: [MusicTrack]) -> some View {
        ChartTrackRowView(
            track: track,
            position: position,
            onPlay: {
                player.setPlaylist(playlist, startIndex: playlist.firstIndex(where: { $0.id == track.id }) ?? 0)
            },
            onLike: {
                Task {
                    await viewModel.toggleLike(track: track)
                }
            }
        )
        .background(
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.themeBlockBackground.opacity(0.5))
                        )
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.themeBlockBackground.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appAccent.opacity(0.15), lineWidth: 0.5)
                        )
                }
            }
        )
    }
    
    // MARK: - Recent Block
    private var recentBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Последнее")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.themeTextPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            if viewModel.isLoadingRecent {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.recentTracks.isEmpty {
                emptyStateView(
                    icon: "music.note",
                    title: "Нет треков",
                    message: "Попробуйте позже"
                )
            } else {
                ForEach(viewModel.recentTracks) { track in
                    trackRow(track: track, playlist: viewModel.recentTracks)
                }
            }
        }
    }
    
    private func trackRow(track: MusicTrack, playlist: [MusicTrack]) -> some View {
        TrackRowView(
            track: track,
            onPlay: {
                player.setPlaylist(playlist, startIndex: playlist.firstIndex(where: { $0.id == track.id }) ?? 0)
            },
            onLike: {
                Task {
                    await viewModel.toggleLike(track: track)
                }
            }
        )
        .background(
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.themeBlockBackground.opacity(0.5))
                        )
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.themeBlockBackground.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appAccent.opacity(0.15), lineWidth: 0.5)
                        )
                }
            }
        )
    }
    
    // MARK: - Liked Content
    private var likedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Любимые")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.themeTextPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                if viewModel.isLoadingLiked {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if viewModel.likedTracks.isEmpty {
                    emptyStateView(
                        icon: "heart",
                        title: "Нет любимых треков",
                        message: "Лайкайте треки, чтобы они появились здесь"
                    )
                } else {
                    ForEach(viewModel.likedTracks) { track in
                        trackRow(track: track, playlist: viewModel.likedTracks)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, player.currentTrack != nil ? 100 : 20)
        }
        .refreshable {
            await viewModel.loadLikedTracks(page: 1, perPage: 20)
        }
    }
    
    // MARK: - Search Content
    private var searchContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Поисковая строка (кастомный стиль)
                    HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.themeTextSecondary)
                    
                    TextField("Поиск треков...", text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.themeTextPrimary)
                        .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                            viewModel.search(query: newValue)
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                            viewModel.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if #available(iOS 26.0, *) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial.opacity(0.2))
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.themeBlockBackground.opacity(0.5))
                                )
                                .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial.opacity(0.2))
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.themeBlockBackground.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.appAccent.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                    }
                )
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Результаты поиска
                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                } else if viewModel.searchQuery.count < 2 {
                    emptyStateView(
                        icon: "magnifyingglass",
                        title: "Начните поиск",
                        message: "Введите минимум 2 символа"
                    )
                } else if viewModel.searchResults.isEmpty {
                    emptyStateView(
                        icon: "music.note",
                        title: "Ничего не найдено",
                        message: "Попробуйте другой запрос"
                    )
                } else {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.searchResults) { track in
                            trackRow(track: track, playlist: viewModel.searchResults)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.bottom, player.currentTrack != nil ? 100 : 20)
        }
        .refreshable {
            // При обновлении в поиске - повторяем поиск, если есть запрос
            if viewModel.searchQuery.count >= 2 {
                viewModel.search(query: viewModel.searchQuery)
            }
        }
    }
    
    // MARK: - Mini Player
    private func miniPlayerView(track: MusicTrack) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            Group {
                if #available(iOS 26.0, *) {
                    liquidGlassMiniPlayer(track: track)
                } else {
                    fallbackMiniPlayer(track: track)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.keyboard)
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassMiniPlayer(track: MusicTrack) -> some View {
        HStack(spacing: 10) {
            // Маленькая обложка
            Button(action: {
                showFullScreenPlayer = true
            }) {
                AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                    switch phase {
                    case .empty, .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.appAccent.opacity(0.7))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 8)
            
            // Название трека
            Button(action: {
                showFullScreenPlayer = true
            }) {
                Text(track.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Кнопка Play/Pause
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    player.togglePlayPause()
                }
            }) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Кнопка следующий трек
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    player.nextTrack()
                }
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regularInteractive, in: RoundedRectangle(cornerRadius: 30))
    }
    
    @ViewBuilder
    private func fallbackMiniPlayer(track: MusicTrack) -> some View {
        HStack(spacing: 10) {
            // Маленькая обложка
            Button(action: {
                showFullScreenPlayer = true
            }) {
                AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                    switch phase {
                    case .empty, .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.appAccent.opacity(0.7))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 8)
            
            // Название трека
            Button(action: {
                showFullScreenPlayer = true
            }) {
                Text(track.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Кнопка Play/Pause
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    player.togglePlayPause()
                }
            }) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Кнопка следующий трек
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    player.nextTrack()
                }
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                )
        )
    }
    
    // MARK: - Empty State
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Enums
enum MusicMainTab {
    case general
    case liked
    case search
}

// MARK: - Chart Type Button
struct ChartTypeButton: View {
    let title: String
    let type: ChartType
    @Binding var selected: ChartType
    
    var body: some View {
        Button(action: {
            selected = type
        }) {
            Text(title)
                .font(.system(size: 13, weight: selected == type ? .semibold : .regular))
                .foregroundColor(selected == type ? Color.appAccent : Color(red: 0.6, green: 0.6, blue: 0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selected == type ? Color.appAccent.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
