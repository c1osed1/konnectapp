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
    
    func getMusic(page: Int = 1, perPage: Int = 50) async throws -> MusicResponse {
        guard let url = URL(string: "\(baseURL)/api/music") else {
            throw AuthError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let finalURL = components.url else {
            throw AuthError.invalidResponse
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        print("🔵 MUSIC REQUEST:")
        print("URL: \(finalURL.absoluteString)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AuthError.invalidResponse
        }
        
        print("🟢 MUSIC RESPONSE:")
        print("Status Code: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let musicResponse = try decoder.decode(MusicResponse.self, from: data)
            print("✅ Decoded Music Response:")
            print("Tracks count: \(musicResponse.tracks.count)")
            return musicResponse
        } catch {
            print("❌ Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString.prefix(500))")
            }
            throw error
        }
    }
    
    func searchMusic(query: String) async throws -> [MusicTrack] {
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
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        
        guard let token = try? KeychainManager.getToken() else {
            throw AuthError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let sessionKey = try? KeychainManager.getSessionKey() {
            request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        }
        
        print("🔵 MUSIC SEARCH REQUEST:")
        print("URL: \(finalURL.absoluteString)")
        print("Query: \(query)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AuthError.invalidResponse
        }
        
        print("🟢 MUSIC SEARCH RESPONSE:")
        print("Status Code: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                try? KeychainManager.deleteTokens()
                throw AuthError.unauthorized
            }
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let tracks = try decoder.decode([MusicTrack].self, from: data)
            print("✅ Decoded Music Search Response:")
            print("Tracks count: \(tracks.count)")
            return tracks
        } catch {
            print("❌ Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString.prefix(500))")
            }
            throw error
        }
    }
}

