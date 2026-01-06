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
                Picker("", selection: $selectedTab) {
                    Text("Общее").tag(MusicMainTab.general)
                    Text("Поиск").tag(MusicMainTab.search)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Контент
                Group {
                    if selectedTab == .general {
                        generalContent
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
                        .foregroundColor(.white.opacity(0.9))
                        .symbolEffect(.pulse)
                }
                .shadow(color: Color.appAccent.opacity(0.5), radius: 20, x: 0, y: 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Мой Вайб")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
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
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
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
    }
    
    // MARK: - Charts Block
    private var chartsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Чарты")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
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
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                        )
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
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
                    .foregroundColor(.white)
                
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
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                        )
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appAccent.opacity(0.15), lineWidth: 0.5)
                        )
                }
            }
        )
    }
    
    // MARK: - Search Content
    private var searchContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Поисковая строка (кастомный стиль)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    
                    TextField("Поиск треков...", text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
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
                                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                                )
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial.opacity(0.2))
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
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
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.keyboard)
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassMiniPlayer(track: MusicTrack) -> some View {
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: 0) {
                // Прогресс-бар
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.themeBlockBackgroundSecondary.opacity(0.5))
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccent.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(player.currentTime / max(player.duration, 1)))
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Плеер
                Button(action: {
                    showFullScreenPlayer = true
                }) {
                    HStack(spacing: 12) {
                        // Обложка с закруглением
                        AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                            switch phase {
                            case .empty, .failure:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.appAccent.opacity(0.4),
                                                Color.appAccent.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.appAccent)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        // Информация о треке
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(track.artist ?? track.user_name ?? "Unknown Artist")
                                .font(.system(size: 13))
                                .foregroundColor(Color.themeTextSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Кнопка Play/Pause (как в Apple Music - просто иконка)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                player.togglePlayPause()
                            }
                        }) {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.appAccent)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.4))
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.themeBlockBackground.opacity(0.8),
                                            Color.themeBackgroundStart.opacity(0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
        }
    }
    
    @ViewBuilder
    private func fallbackMiniPlayer(track: MusicTrack) -> some View {
        VStack(spacing: 0) {
            // Прогресс-бар
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.5))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(player.currentTime / max(player.duration, 1)))
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Плеер
            Button(action: {
                showFullScreenPlayer = true
            }) {
                HStack(spacing: 12) {
                    // Обложка с закруглением
                    AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                        switch phase {
                        case .empty, .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appAccent.opacity(0.4),
                                            Color.appAccent.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.appAccent)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Информация о треке
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist ?? track.user_name ?? "Unknown Artist")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Кнопка Play/Pause (как в Apple Music - просто иконка)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            player.togglePlayPause()
                        }
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.8),
                                        Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appAccent.opacity(0.3),
                                Color.appAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
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
