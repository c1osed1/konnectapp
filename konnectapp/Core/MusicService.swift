import Foundation
import UIKit

class MusicService {
    static let shared = MusicService()
    private let baseURL = "https://k-connect.ru"
    
    private var userAgent: String {
        let systemVersion = UIDevice.current.systemVersion
        let scale: CGFloat
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            scale = window.screen.scale
        } else {
            scale = 3.0
        }
        return "KConnect-iOS/1.0 (iPhone; iOS \(systemVersion); Scale/\(scale))"
    }
    
    private init() {}
    
    private func makeRequest(url: URL, method: String = "GET") throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        if method == "POST" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    // MARK: - Мой Вайб
    func getMyVibe() async throws -> MyVibeResponse {
        guard let url = URL(string: "\(baseURL)/api/music/my-vibe") else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(MyVibeResponse.self, from: data)
    }
    
    // MARK: - Чарты
    func getCharts(type: ChartType = .popular, limit: Int = 50) async throws -> ChartsResponse {
        guard let url = URL(string: "\(baseURL)/api/music/charts") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let finalURL = components.url else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: finalURL)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ChartsResponse.self, from: data)
    }
    
    // MARK: - Последние треки
    func getTracks(type: TrackListType = .all, offset: Int = 0, limit: Int = 10, sort: String? = nil) async throws -> TracksResponse {
        guard let url = URL(string: "\(baseURL)/api/music/tracks") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }
        
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: finalURL)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(TracksResponse.self, from: data)
    }
    
    // MARK: - Поиск
    func searchMusic(query: String) async throws -> [MusicTrack] {
        guard query.count >= 2 else {
            return []
        }
        
        guard let url = URL(string: "\(baseURL)/api/music/search") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let finalURL = components.url else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: finalURL)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([MusicTrack].self, from: data)
    }
    
    // MARK: - Воспроизведение
    func playTrack(trackId: Int64) async throws -> PlayResponse {
        guard let url = URL(string: "\(baseURL)/api/music/\(trackId)/play") else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
            throw AuthError.unauthorized
        }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(PlayResponse.self, from: data)
    }
    
    // MARK: - Лайк/Дизлайк
    func toggleLike(trackId: Int64) async throws -> LikeResponse {
        guard let url = URL(string: "\(baseURL)/api/music/\(trackId)/like") else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(LikeResponse.self, from: data)
    }
    
    // MARK: - Получение информации о треке
    func getTrack(trackId: Int64) async throws -> TrackDetailResponse {
        guard let url = URL(string: "\(baseURL)/api/music/\(trackId)") else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(TrackDetailResponse.self, from: data)
    }
    
    // MARK: - Получение текстов песни
    func getLyrics(trackId: Int64) async throws -> LyricsResponse {
        guard let url = URL(string: "\(baseURL)/api/music/\(trackId)/lyrics") else {
            throw AuthError.invalidResponse
        }
        
        let request = try makeRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(LyricsResponse.self, from: data)
    }
}

// MARK: - Enums
enum ChartType: String {
    case popular = "popular"
    case plays = "plays"
    case likes = "likes"
    case new = "new"
    case combined = "combined"
}

enum TrackListType: String {
    case all = "all"
    case liked = "liked"
    case popular = "popular"
    case new = "new"
    case random = "random"
}

