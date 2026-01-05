import SwiftUI

struct MusicSelectionModal: View {
    @Binding var isPresented: Bool
    @Binding var selectedTrack: MusicTrack?
    @State private var tracks: [MusicTrack] = []
    @State private var isLoading: Bool = false
    @State private var currentPage: Int = 1
    @State private var hasMore: Bool = true
    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05)
                    .ignoresSafeArea()
                
                if isLoading && tracks.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tracks) { track in
                                MusicTrackRow(
                                    track: track,
                                    isSelected: selectedTrack?.id == track.id,
                                    onSelect: {
                                        selectedTrack = track
                                        isPresented = false
                                    }
                                )
                            }
                            
                            if !searchText.isEmpty && hasMore && !isLoading {
                                Button(action: {
                                    loadMoreTracks()
                                }) {
                                    Text("Загрузить еще")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                                        .padding(.vertical, 12)
                                }
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Выберите трек")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
            .searchable(text: $searchText, prompt: "Поиск треков")
            .onChange(of: searchText) { oldValue, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if !Task.isCancelled {
                        await performSearch(query: newValue)
                    }
                }
            }
            .task {
                if searchText.isEmpty {
                    await loadTracks()
                }
            }
        }
    }
    
    private func performSearch(query: String) async {
        isLoading = true
        defer { isLoading = false }
        
        if query.isEmpty {
            await loadTracks()
            return
        }
        
        do {
            let searchResults = try await MusicService.shared.searchMusic(query: query)
            await MainActor.run {
                tracks = searchResults
                hasMore = false
            }
        } catch {
            print("❌ Error searching tracks: \(error)")
        }
    }
    
    private func loadTracks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await MusicService.shared.getMusic(page: 1, perPage: 50)
            await MainActor.run {
                tracks = response.tracks
                hasMore = response.current_page < response.pages
                currentPage = response.current_page
            }
        } catch {
            print("❌ Error loading tracks: \(error)")
        }
    }
    
    private func loadMoreTracks() {
        guard !isLoading && hasMore && searchText.isEmpty else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let response = try await MusicService.shared.getMusic(page: currentPage + 1, perPage: 50)
                await MainActor.run {
                    tracks.append(contentsOf: response.tracks)
                    hasMore = response.current_page < response.pages
                    currentPage = response.current_page
                }
            } catch {
                print("❌ Error loading more tracks: \(error)")
            }
        }
    }
}

struct MusicTrackRow: View {
    let track: MusicTrack
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                            .frame(width: 48, height: 48)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let artist = track.artist {
                        Text(artist)
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.5))
            )
        }
    }
}

