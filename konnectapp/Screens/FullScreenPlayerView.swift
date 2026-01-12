import SwiftUI
import AVFoundation
import MediaPlayer
import Combine
import UIKit

struct FullScreenPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = MusicPlayer.shared
    @StateObject private var viewModel = FullScreenPlayerViewModel()
    @State private var showLyrics: Bool = false
    @State private var currentLyricIndex: Int = -1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundCover(geometry: geometry)
                VStack(spacing: 0) {
                    topBar.padding(.top, 8).padding(.horizontal, 16).padding(.bottom, 8)
                    Group {
                        if showLyrics { lyricsView(geometry: geometry) } else { coverArtView(geometry: geometry) }
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    trackInfoView.padding(.horizontal, 16).padding(.top, 12)
                    progressView.padding(.horizontal, 16).padding(.top, 12)
                    controlsView.padding(.horizontal, 16).padding(.top, 20)
                    additionalControlsView.padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 16)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black.ignoresSafeArea(edges: .all))
            .onAppear {
                loadTrackData()
            }
            .onChange(of: player.currentTrack?.id) { oldValue, newValue in
                if newValue != oldValue { loadTrackData() }
            }
            .onChange(of: player.currentTime) { oldValue, newValue in
                updateActiveLyric()
            }
        }
    }
    
    private func loadTrackData() {
        if let track = player.currentTrack {
            Task {
                await viewModel.loadTrackDetails(trackId: track.id)
                await viewModel.loadLyrics(trackId: track.id)
                currentLyricIndex = -1
            }
        }
    }
    
    private func backgroundCover(geometry: GeometryProxy) -> some View {
        ZStack {
            Group {
                if let coverPath = viewModel.trackDetail?.cover_path ?? player.currentTrack?.cover_path,
                   let coverURL = URL(string: coverPath) {
                    CachedAsyncImage(url: coverURL, cacheType: .musicCover)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blur(radius: 80)
                } else { Color.black }
            }
            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.95),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea(edges: .all)
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down").font(.system(size: 18, weight: .medium)).foregroundColor(.white).frame(width: 44, height: 44)
            }
            Spacer()
            Text("Сейчас играет").font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.8))
            Spacer()
            Button(action: {}) {
                Image(systemName: "ellipsis").font(.system(size: 18, weight: .medium)).foregroundColor(.white).frame(width: 44, height: 44)
            }
        }
    }
    
    private func coverArtView(geometry: GeometryProxy) -> some View {
        let size = max(100, min(geometry.size.width - 80, geometry.size.height * 0.6))
        return Group {
            if let coverPath = viewModel.trackDetail?.cover_path ?? player.currentTrack?.cover_path,
               let coverURL = URL(string: coverPath) {
                CachedAsyncImage(url: coverURL, cacheType: .musicCover)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 20)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Color.appAccent.opacity(0.4), Color.appAccent.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size, height: size)
                    .overlay(Image(systemName: "music.note").font(.system(size: 60)).foregroundColor(Color.appAccent))
            }
        }
    }
    
    private func lyricsView(geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let syncedLyrics = viewModel.lyrics?.synced_lyrics, !syncedLyrics.isEmpty {
                        ForEach(Array(syncedLyrics.enumerated()), id: \.element.id) { index, line in
                            Text(line.text)
                                .font(.system(size: currentLyricIndex == index ? 28 : 22, weight: currentLyricIndex == index ? .bold : .regular))
                                .foregroundColor(currentLyricIndex == index ? .white : (index < currentLyricIndex ? .white.opacity(0.6) : .white.opacity(0.3)))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 8)
                                .blur(radius: index != currentLyricIndex ? 2 : 0)
                                .id(line.id)
                                .animation(.easeInOut(duration: 0.3), value: currentLyricIndex)
                        }
                    } else if let lyrics = viewModel.lyrics?.lyrics, !lyrics.isEmpty {
                        ForEach(Array(lyrics.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                            if !line.isEmpty {
                                Text(line).font(.system(size: 22)).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.leading).padding(.horizontal, 8)
                            }
                        }
                    } else { coverArtView(geometry: geometry) }
                }
                .padding(.vertical, geometry.size.height * 0.3)
                .frame(minHeight: geometry.size.height)
            }
            .onChange(of: currentLyricIndex) { oldValue, newValue in
                if let syncedLyrics = viewModel.lyrics?.synced_lyrics, newValue >= 0 && newValue < syncedLyrics.count {
                    withAnimation(.easeInOut(duration: 0.5)) { proxy.scrollTo(syncedLyrics[newValue].id, anchor: .center) }
                }
            }
        }
    }
    
    private var trackInfoView: some View {
        VStack(spacing: 8) {
            Text(viewModel.trackDetail?.title ?? player.currentTrack?.title ?? "Unknown")
                .font(.system(size: 24, weight: .bold)).foregroundColor(.white).multilineTextAlignment(.center)
            Text(viewModel.trackDetail?.artist ?? player.currentTrack?.artist ?? player.currentTrack?.user_name ?? "Unknown Artist")
                .font(.system(size: 18, weight: .medium)).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
        }
    }
    
    private var progressView: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.3)).frame(height: 4)
                    Capsule().fill(Color.white).frame(width: geometry.size.width * CGFloat(player.currentTime / max(player.duration, 1)), height: 4)
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let percentage = value.location.x / geometry.size.width
                    let newTime = max(0, min(player.duration, player.duration * Double(percentage)))
                    player.seek(to: newTime)
                })
            }.frame(height: 10)
            HStack {
                Text(formatTime(player.currentTime)).font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(formatTime(player.duration)).font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 20) {
            Button(action: { player.previousTrack() }) {
                Image(systemName: "backward.fill").font(.system(size: 42)).foregroundColor(.white).frame(width: 90, height: 90)
            }
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { player.togglePlayPause() } }) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 82, weight: .medium)).foregroundColor(.white).frame(width: 110, height: 110)
            }
            Button(action: { player.nextTrack() }) {
                Image(systemName: "forward.fill").font(.system(size: 42)).foregroundColor(.white).frame(width: 90, height: 90)
            }
        }
    }
    
    private var additionalControlsView: some View {
        let hasLyrics = (viewModel.lyrics?.synced_lyrics != nil && !viewModel.lyrics!.synced_lyrics!.isEmpty) || (viewModel.lyrics?.lyrics != nil && !viewModel.lyrics!.lyrics!.isEmpty)
        return HStack(spacing: 40) {
            if hasLyrics {
                Button(action: { withAnimation { showLyrics.toggle() } }) {
                    Image(systemName: showLyrics ? "music.note" : "text.alignleft").font(.system(size: 20)).foregroundColor(.white.opacity(0.8))
                }
            } else {
                Spacer()
            }
            Spacer()
            Button(action: {
                if let track = player.currentTrack {
                    Task { await viewModel.toggleLike(trackId: track.id) }
                }
            }) {
                Image(systemName: viewModel.isLiked ? "heart.fill" : "heart").font(.system(size: 20)).foregroundColor(viewModel.isLiked ? .red : .white.opacity(0.8))
            }
            Spacer()
            ShareButton(trackId: player.currentTrack?.id)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func updateActiveLyric() {
        guard let syncedLyrics = viewModel.lyrics?.synced_lyrics, !syncedLyrics.isEmpty else {
            currentLyricIndex = -1
            return
        }
        let currentTimeMs = Int(player.currentTime * 1000)
        var newIndex = -1
        for (index, line) in syncedLyrics.enumerated() {
            let nextLine = index < syncedLyrics.count - 1 ? syncedLyrics[index + 1] : nil
            if currentTimeMs >= line.startTimeMs {
                if let next = nextLine {
                    if currentTimeMs < next.startTimeMs { newIndex = index; break }
                } else { newIndex = index; break }
            }
        }
        if newIndex != currentLyricIndex {
            withAnimation(.easeInOut(duration: 0.3)) { currentLyricIndex = newIndex }
        }
    }
}

@MainActor
class FullScreenPlayerViewModel: ObservableObject {
    @Published var trackDetail: MusicTrackDetail?
    @Published var lyrics: LyricsResponse?
    @Published var isLiked: Bool = false
    @Published var isLoading: Bool = false
    private let musicService = MusicService.shared
    
    func loadTrackDetails(trackId: Int64) async {
        isLoading = true
        do {
            let response = try await musicService.getTrack(trackId: trackId)
            trackDetail = response.track
            isLiked = response.track.likes_count.map { $0 > 0 } ?? false
        } catch { print("❌ Error loading track details: \(error)") }
        isLoading = false
    }
    
    func loadLyrics(trackId: Int64) async {
        do {
            let response = try await musicService.getLyrics(trackId: trackId)
            lyrics = response
        } catch { print("❌ Error loading lyrics: \(error)") }
    }
    
    func toggleLike(trackId: Int64) async {
        do {
            let response = try await musicService.toggleLike(trackId: trackId)
            isLiked = response.message.contains("добавлен")
        } catch { print("❌ Error toggling like: \(error)") }
    }
}

struct ShareButton: View {
    let trackId: Int64?
    @State private var showShareSheet = false
    
    var body: some View {
        Button(action: {
            if trackId != nil {
                showShareSheet = true
            }
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
        }
        .sheet(isPresented: $showShareSheet) {
            if let trackId = trackId, let url = URL(string: "https://k-connect.ru/music/\(trackId)") {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
