import Foundation
import SwiftUI
import Combine

@MainActor
class MusicViewModel: ObservableObject {
    @Published var myVibeTracks: [MusicTrack] = []
    @Published var charts: ChartsData?
    @Published var recentTracks: [MusicTrack] = []
    @Published var searchResults: [MusicTrack] = []
    @Published var searchQuery: String = ""
    
    @Published var isLoadingMyVibe: Bool = false
    @Published var isLoadingCharts: Bool = false
    @Published var isLoadingRecent: Bool = false
    @Published var isSearching: Bool = false
    
    @Published var errorMessage: String?
    
    @Published var selectedChartType: ChartType = .popular
    @Published var selectedTrackListType: TrackListType = .all
    
    private var searchTask: Task<Void, Never>?
    private let musicService = MusicService.shared
    
    // MARK: - My Vibe
    func loadMyVibe() async {
        isLoadingMyVibe = true
        errorMessage = nil
        
        do {
            let response = try await musicService.getMyVibe()
            myVibeTracks = response.tracks
        } catch {
            errorMessage = "Не удалось загрузить Мой Вайб"
            print("❌ Error loading My Vibe: \(error)")
        }
        
        isLoadingMyVibe = false
    }
    
    // MARK: - Charts
    func loadCharts(type: ChartType = .popular) async {
        isLoadingCharts = true
        errorMessage = nil
        selectedChartType = type
        
        do {
            let response = try await musicService.getCharts(type: type, limit: 50)
            charts = response.charts
        } catch {
            errorMessage = "Не удалось загрузить чарты"
            print("❌ Error loading charts: \(error)")
        }
        
        isLoadingCharts = false
    }
    
    // MARK: - Recent Tracks
    func loadRecentTracks(type: TrackListType = .all, offset: Int = 0) async {
        isLoadingRecent = true
        errorMessage = nil
        selectedTrackListType = type
        
        do {
            let response = try await musicService.getTracks(type: type, offset: offset, limit: 20, sort: "newest")
            if offset == 0 {
                recentTracks = response.tracks
            } else {
                recentTracks.append(contentsOf: response.tracks)
            }
        } catch {
            errorMessage = "Не удалось загрузить треки"
            print("❌ Error loading tracks: \(error)")
        }
        
        isLoadingRecent = false
    }
    
    // MARK: - Search
    func search(query: String) {
        searchQuery = query
        
        // Отменяем предыдущий поиск
        searchTask?.cancel()
        
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            isSearching = true
            errorMessage = nil
            
            do {
                let results = try await musicService.searchMusic(query: query)
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Ошибка поиска"
                    print("❌ Error searching: \(error)")
                }
            }
            
            isSearching = false
        }
    }
    
    // MARK: - Like/Unlike
    func toggleLike(track: MusicTrack) async {
        do {
            let response = try await musicService.toggleLike(trackId: track.id)
            
            // Обновляем трек в списках через перезагрузку данных
            // Это проще, чем обновлять каждый трек вручную
            let isLiked = response.message.contains("добавлен")
            
            // Обновляем локально для быстрого отклика UI
            updateTrackLocally(trackId: track.id, isLiked: isLiked, likesCount: response.likes_count)
        } catch {
            errorMessage = "Не удалось обновить лайк"
            print("❌ Error toggling like: \(error)")
        }
    }
    
    private func updateTrackLocally(trackId: Int64, isLiked: Bool, likesCount: Int) {
        // Обновляем в My Vibe
        if myVibeTracks.contains(where: { $0.id == trackId }) {
            // Перезагружаем My Vibe для актуальных данных
            Task {
                await loadMyVibe()
            }
        }
        
        // Обновляем в Recent Tracks
        if recentTracks.contains(where: { $0.id == trackId }) {
            Task {
                await loadRecentTracks(type: selectedTrackListType, offset: 0)
            }
        }
        
        // Обновляем в Search Results - просто обновляем локально
        if searchResults.contains(where: { $0.id == trackId }) {
            // Для поиска обновляем локально, так как перезагрузка сбросит результаты
            // Но так как MusicTrack - immutable struct, нужно перезагрузить поиск
            if searchQuery.count >= 2 {
                search(query: searchQuery)
            }
        }
        
        // Обновляем в Charts
        if charts != nil {
            Task {
                await loadCharts(type: selectedChartType)
            }
        }
    }
}

