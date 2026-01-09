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
            
            ScrollView {
                VStack(spacing: 0) {
                    myVibeBlock
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    
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
                                        .stroke(Color.appAccent.opacity(0.15), lineWidth: 0.5)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
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
                .padding(.bottom, player.currentTrack != nil ? 100 : 20)
            }
            .refreshable {
                if selectedTab == .general {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.loadCharts(type: viewModel.selectedChartType) }
                        group.addTask { await viewModel.loadRecentTracks(type: viewModel.selectedTrackListType, offset: 0) }
                    }
                } else if selectedTab == .liked {
                    await viewModel.loadLikedTracks(page: 1, perPage: 20)
                }
            }
            
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
    
    @State private var gradientOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.5
    @State private var gradientColors: [Color] = ImageColorExtractor.getDefaultColors()
    @State private var isExtractingColors: Bool = false
    @State private var animationTimer: Timer?
    @State private var isReversing: Bool = false
    
    private var myVibeBlock: some View {
        Button(action: {
            if player.isPlaying && player.currentTrack != nil {
                player.pause()
            } else if !viewModel.myVibeTracks.isEmpty {
                if player.currentTrack == nil {
                    player.setPlaylist(viewModel.myVibeTracks, startIndex: 0)
                } else {
                    player.play()
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: gradientColors.map { color in
                                Color(
                                    red: min(1.0, color.components.red + Foundation.sin(gradientOffset) * 0.1),
                                    green: min(1.0, color.components.green + Foundation.cos(gradientOffset * 0.7) * 0.1),
                                    blue: min(1.0, color.components.blue + Foundation.sin(gradientOffset * 1.3) * 0.1)
                                )
                            },
                            center: UnitPoint(
                                x: 0.5 + Foundation.sin(gradientOffset) * 0.25,
                                y: 0.5 + Foundation.cos(gradientOffset) * 0.25
                            ),
                            startRadius: 50,
                            endRadius: 250
                        )
                    )
                    .blur(radius: 25)
                    .overlay(
                        RadialGradient(
                            colors: [
                                gradientColors.first?.opacity(0.8 + glowIntensity * 0.2) ?? Color.white.opacity(0.8),
                                gradientColors[safe: 1]?.opacity(0.6 + glowIntensity * 0.2) ?? Color.white.opacity(0.6),
                                Color.clear
                            ],
                            center: UnitPoint(
                                x: 0.5 + Foundation.cos(gradientOffset * 0.6) * 0.3,
                                y: 0.5 + Foundation.sin(gradientOffset * 0.6) * 0.3
                            ),
                            startRadius: 40,
                            endRadius: 180
                        )
                        .blur(radius: 20)
                    )
                    .overlay(
                        RadialGradient(
                            colors: [
                                gradientColors[safe: 2]?.opacity(0.5 + glowIntensity * 0.2) ?? Color.white.opacity(0.5),
                                gradientColors[safe: 3]?.opacity(0.4) ?? Color.white.opacity(0.4),
                                Color.clear
                            ],
                            center: UnitPoint(
                                x: 0.5 + Foundation.sin(gradientOffset * 0.8) * 0.35,
                                y: 0.5 + Foundation.cos(gradientOffset * 0.8) * 0.35
                            ),
                            startRadius: 60,
                            endRadius: 220
                        )
                        .blur(radius: 30)
                    )
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                        Text("Моя волна")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    Spacer()
                    if !viewModel.isLoadingMyVibe && !viewModel.myVibeTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            if let currentTrack = player.currentTrack ?? viewModel.myVibeTracks.first {
                                Text(currentTrack.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(currentTrack.artist ?? currentTrack.user_name ?? "Unknown Artist")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else if viewModel.isLoadingMyVibe {
                        HStack {
                            ProgressView().tint(.white)
                            Text("Загрузка...")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        Text("Лайкайте треки для рекомендаций")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startGradientAnimation()
            extractColorsFromCurrentTrack()
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
        }
        .onChange(of: player.currentTrack?.id) { oldValue, newValue in
            extractColorsFromCurrentTrack()
        }
    }
    
    private func extractColorsFromCurrentTrack() {
        guard let track = player.currentTrack,
              let coverPath = track.cover_path,
              let coverURL = URL(string: coverPath) else {
            withAnimation(.easeInOut(duration: 1.0)) {
                gradientColors = ImageColorExtractor.getDefaultColors()
            }
            return
        }
        isExtractingColors = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: coverURL)
                if let image = UIImage(data: data) {
                    let extractedColors = ImageColorExtractor.extractDominantColors(from: image, count: 5)
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            gradientColors = extractedColors.isEmpty ? ImageColorExtractor.getDefaultColors() : extractedColors
                        }
                        isExtractingColors = false
                    }
                } else {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            gradientColors = ImageColorExtractor.getDefaultColors()
                        }
                        isExtractingColors = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        gradientColors = ImageColorExtractor.getDefaultColors()
                    }
                    isExtractingColors = false
                }
            }
        }
    }
    
    private func startGradientAnimation() {
        withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowIntensity = 0.6
        }
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [self] _ in
            let step: CGFloat = 0.015
            if isReversing {
                gradientOffset -= step
                if gradientOffset <= 0 {
                    gradientOffset = 0
                    isReversing = false
                }
            } else {
                gradientOffset += step
                if gradientOffset >= .pi * 2 {
                    gradientOffset = .pi * 2
                    isReversing = true
                }
            }
        }
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private var generalContent: some View {
        LazyVStack(spacing: 0) {
            chartsBlock.padding(.bottom, 24)
            recentBlock
        }
    }
    
    private var chartsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
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
    
    private var likedContent: some View {
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
                emptyStateView(icon: "heart", title: "Нет любимых треков", message: "Лайкайте треки, чтобы они появились здесь")
            } else {
                ForEach(viewModel.likedTracks) { track in
                    trackRow(track: track, playlist: viewModel.likedTracks)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var searchContent: some View {
        VStack(spacing: 16) {
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
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.themeBlockBackground.opacity(0.5)))
                            .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.themeBlockBackground.opacity(0.5)))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appAccent.opacity(0.15), lineWidth: 0.5))
                    }
                }
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)
            if viewModel.isSearching {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 100)
            } else if viewModel.searchQuery.count < 2 {
                emptyStateView(icon: "magnifyingglass", title: "Начните поиск", message: "Введите минимум 2 символа")
            } else if viewModel.searchResults.isEmpty {
                emptyStateView(icon: "music.note", title: "Ничего не найдено", message: "Попробуйте другой запрос")
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.searchResults) { track in
                        trackRow(track: track, playlist: viewModel.searchResults)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
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
            Button(action: { showFullScreenPlayer = true }) {
                Text(track.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
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
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 30))
    }
    @ViewBuilder
    private func fallbackMiniPlayer(track: MusicTrack) -> some View {
        HStack(spacing: 10) {
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
            Button(action: { showFullScreenPlayer = true }) {
                Text(track.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
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
