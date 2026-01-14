import SwiftUI

struct CacheSettingsModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var cacheSize: CacheSize = CacheSize(postsImages: 0, avatars: 0, banners: 0, tracks: 0, badges: 0, musicCovers: 0, total: 0)
    @State private var selectedSegments: Set<CacheSegment> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackgroundStart,
                        Color.themeBackgroundEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    CachePieChart(cacheSize: cacheSize, selectedSegments: $selectedSegments)
                        .frame(height: 220)
                        .padding(.top, 250)
                    
                    VStack(spacing: 12) {
                        CacheInfoRow(
                            title: "Изображения постов",
                            size: cacheSize.formattedPostsImages(),
                            isSelected: selectedSegments.contains(.postsImages),
                            action: {
                                if selectedSegments.contains(.postsImages) {
                                    selectedSegments.remove(.postsImages)
                                } else {
                                    selectedSegments.insert(.postsImages)
                                }
                            }
                        )
                        
                        CacheInfoRow(
                            title: "Аватарки",
                            size: cacheSize.formattedAvatars(),
                            isSelected: selectedSegments.contains(.avatars),
                            action: {
                                if selectedSegments.contains(.avatars) {
                                    selectedSegments.remove(.avatars)
                                } else {
                                    selectedSegments.insert(.avatars)
                                }
                            }
                        )
                        
                        CacheInfoRow(
                            title: "Баннеры",
                            size: cacheSize.formattedBanners(),
                            isSelected: selectedSegments.contains(.banners),
                            action: {
                                if selectedSegments.contains(.banners) {
                                    selectedSegments.remove(.banners)
                                } else {
                                    selectedSegments.insert(.banners)
                                }
                            }
                        )
                        
                        CacheInfoRow(
                            title: "Треки",
                            size: cacheSize.formattedTracks(),
                            isSelected: selectedSegments.contains(.tracks),
                            action: {
                                if selectedSegments.contains(.tracks) {
                                    selectedSegments.remove(.tracks)
                                } else {
                                    selectedSegments.insert(.tracks)
                                }
                            }
                        )
                        
                        CacheInfoRow(
                            title: "Бейджи",
                            size: cacheSize.formattedBadges(),
                            isSelected: selectedSegments.contains(.badges),
                            action: {
                                if selectedSegments.contains(.badges) {
                                    selectedSegments.remove(.badges)
                                } else {
                                    selectedSegments.insert(.badges)
                                }
                            }
                        )
                        
                        CacheInfoRow(
                            title: "Обложки музыки",
                            size: cacheSize.formattedMusicCovers(),
                            isSelected: selectedSegments.contains(.musicCovers),
                            action: {
                                if selectedSegments.contains(.musicCovers) {
                                    selectedSegments.remove(.musicCovers)
                                } else {
                                    selectedSegments.insert(.musicCovers)
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        clearSelectedCache()
                    }) {
                        Text(selectedSegments.isEmpty ? "Выберите элементы" : "Очистить выбранное (\(selectedSegments.count))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedSegments.isEmpty ? Color.gray.opacity(0.3) : Color.appAccent)
                            )
                    }
                    .disabled(selectedSegments.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Button(action: {
                        CacheManager.shared.clearAllCache()
                        loadCacheSize()
                    }) {
                        Text("Очистить всё")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Управление кешем")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(Color.themeTextPrimary)
                }
            }
            .onAppear {
                loadCacheSize()
            }
        }
    }
    
    private func loadCacheSize() {
        cacheSize = CacheManager.shared.getCacheSize()
    }
    
    private func clearSelectedCache() {
        for segment in selectedSegments {
            switch segment {
            case .postsImages:
                CacheManager.shared.clearPostsImagesCache()
            case .avatars:
                CacheManager.shared.clearAvatarsCache()
            case .banners:
                CacheManager.shared.clearBannersCache()
            case .tracks:
                CacheManager.shared.clearTracksCache()
            case .badges:
                CacheManager.shared.clearBadgesCache()
            case .musicCovers:
                CacheManager.shared.clearMusicCoversCache()
            }
        }
        selectedSegments.removeAll()
        loadCacheSize()
    }
}

enum CacheSegment {
    case postsImages
    case avatars
    case banners
    case tracks
    case badges
    case musicCovers
}

struct CachePieChart: View {
    let cacheSize: CacheSize
    @Binding var selectedSegments: Set<CacheSegment>
    
    private var segments: [(start: CGFloat, end: CGFloat, ratio: CGFloat, segment: CacheSegment, color: Color)] {
        guard cacheSize.total > 0 else { return [] }
        
        let postsRatio = CGFloat(cacheSize.postsImages) / CGFloat(max(cacheSize.total, 1))
        let avatarsRatio = CGFloat(cacheSize.avatars) / CGFloat(max(cacheSize.total, 1))
        let bannersRatio = CGFloat(cacheSize.banners) / CGFloat(max(cacheSize.total, 1))
        let tracksRatio = CGFloat(cacheSize.tracks) / CGFloat(max(cacheSize.total, 1))
        let badgesRatio = CGFloat(cacheSize.badges) / CGFloat(max(cacheSize.total, 1))
        let musicCoversRatio = CGFloat(cacheSize.musicCovers) / CGFloat(max(cacheSize.total, 1))
        
        var result: [(start: CGFloat, end: CGFloat, ratio: CGFloat, segment: CacheSegment, color: Color)] = []
        var currentStart: CGFloat = 0
        
        if postsRatio > 0 {
            let isSelected = selectedSegments.contains(.postsImages)
            result.append((currentStart, currentStart + postsRatio, postsRatio, .postsImages, isSelected ? Color.appAccent : Color.appAccent.opacity(0.6)))
            currentStart += postsRatio
        }
        
        if avatarsRatio > 0 {
            let isSelected = selectedSegments.contains(.avatars)
            result.append((currentStart, currentStart + avatarsRatio, avatarsRatio, .avatars, isSelected ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.6)))
            currentStart += avatarsRatio
        }
        
        if bannersRatio > 0 {
            let isSelected = selectedSegments.contains(.banners)
            result.append((currentStart, currentStart + bannersRatio, bannersRatio, .banners, isSelected ? Color(red: 1.0, green: 0.6, blue: 0.2) : Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.6)))
            currentStart += bannersRatio
        }
        
        if tracksRatio > 0 {
            let isSelected = selectedSegments.contains(.tracks)
            result.append((currentStart, currentStart + tracksRatio, tracksRatio, .tracks, isSelected ? Color(red: 0.2, green: 0.6, blue: 1.0) : Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.6)))
            currentStart += tracksRatio
        }
        
        if badgesRatio > 0 {
            let isSelected = selectedSegments.contains(.badges)
            result.append((currentStart, currentStart + badgesRatio, badgesRatio, .badges, isSelected ? Color(red: 0.8, green: 0.4, blue: 0.9) : Color(red: 0.8, green: 0.4, blue: 0.9).opacity(0.6)))
            currentStart += badgesRatio
        }
        
        if musicCoversRatio > 0 {
            let isSelected = selectedSegments.contains(.musicCovers)
            result.append((currentStart, 1.0, musicCoversRatio, .musicCovers, isSelected ? Color(red: 0.9, green: 0.5, blue: 0.2) : Color(red: 0.9, green: 0.5, blue: 0.2).opacity(0.6)))
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.themeBlockBackgroundSecondary)
                .frame(width: 220, height: 220)
            
            // Segments using Path for proper rendering
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 16
                
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    Path { path in
                        let startAngle = Angle(radians: Double(segment.start) * 2 * .pi - .pi / 2)
                        let endAngle = Angle(radians: Double(segment.end) * 2 * .pi - .pi / 2)
                        
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                    }
                    .stroke(segment.color, style: StrokeStyle(lineWidth: 32, lineCap: .round, lineJoin: .round))
                    .onTapGesture {
                        if selectedSegments.contains(segment.segment) {
                            selectedSegments.remove(segment.segment)
                        } else {
                            selectedSegments.insert(segment.segment)
                        }
                    }
                }
            }
            .frame(width: 220, height: 220)
            
            // Inner circle
            Circle()
                .fill(Color.themeBackgroundStart)
                .frame(width: 140, height: 140)
            
            VStack(spacing: 4) {
                Text(cacheSize.formatted())
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color.themeTextPrimary)
                Text("Всего")
                    .font(.system(size: 13))
                    .foregroundColor(Color.themeTextSecondary)
            }
        }
    }
}

struct CacheInfoRow: View {
    let title: String
    let size: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appAccent : Color.gray.opacity(0.3))
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.themeTextPrimary)
                    }
                }
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(Color.themeTextPrimary)
                
                Spacer()
                
                Text(size)
                    .font(.system(size: 14))
                    .foregroundColor(Color.themeTextSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.appAccent.opacity(0.15) : Color.themeBlockBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

