import Foundation
import UIKit

class PollService {
    static let shared = PollService()
    private let baseURL = "https://k-connect.ru"
    
    private var userAgent: String {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let scale = window.screen.scale
            return "KConnect-iOS/1.2.5 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/\(String(format: "%.1f", scale)))"
        }
        return "KConnect-iOS/1.2.5 (iPhone; iOS \(UIDevice.current.systemVersion); Scale/3.0)"
    }
    
    private init() {}
    
    func vote(pollId: Int64, optionIds: [Int64]) async throws -> Poll {
        guard let token = try KeychainManager.getToken() else {
            throw PollError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PollError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/polls/\(pollId)/vote") else {
            throw PollError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        let body: [String: Any] = [
            "option_ids": optionIds
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🟢 VOTE REQUEST: URL: \(url.absoluteString) Option IDs: \(optionIds)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PollError.invalidResponse
        }
        
        print("🟢 VOTE RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let voteResponse = try decoder.decode(VotePollResponse.self, from: data)
                return voteResponse.poll
            } catch {
                print("❌ JSON Decoding Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response body: \(jsonString)")
                }
                throw PollError.decodingError(error)
            }
        } else {
            print("❌ VOTE ERROR: Status Code: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw PollError.serverError(httpResponse.statusCode)
        }
    }
    
    func getPollResults(pollId: Int64) async throws -> Poll {
        guard let token = try KeychainManager.getToken() else {
            throw PollError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PollError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/polls/\(pollId)/results") else {
            throw PollError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🟢 GET POLL RESULTS REQUEST: URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PollError.invalidResponse
        }
        
        print("🟢 GET POLL RESULTS RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Poll results response body: \(jsonString)")
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let resultsResponse = try decoder.decode(PollResultsResponse.self, from: data)
                print("✅ Poll results decoded successfully: poll ID=\(resultsResponse.poll.id), options count=\(resultsResponse.poll.options.count)")
                return resultsResponse.poll
            } catch {
                print("❌ JSON Decoding Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response body: \(jsonString)")
                }
                throw PollError.decodingError(error)
            }
        } else {
            print("❌ GET POLL RESULTS ERROR: Status Code: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw PollError.serverError(httpResponse.statusCode)
        }
    }
    
    func removeVote(pollId: Int64) async throws -> Poll {
        guard let token = try KeychainManager.getToken() else {
            throw PollError.notAuthenticated
        }
        
        guard let sessionKey = try KeychainManager.getSessionKey() else {
            throw PollError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/polls/\(pollId)/vote") else {
            throw PollError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-Client")
        request.setValue(sessionKey, forHTTPHeaderField: "X-Session-Key")
        
        print("🟢 REMOVE VOTE REQUEST: URL: \(url.absoluteString) Method: DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PollError.invalidResponse
        }
        
        print("🟢 REMOVE VOTE RESPONSE: Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let voteResponse = try decoder.decode(VotePollResponse.self, from: data)
                return voteResponse.poll
            } catch {
                print("❌ JSON Decoding Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response body: \(jsonString)")
                }
                throw PollError.decodingError(error)
            }
        } else {
            print("❌ REMOVE VOTE ERROR: Status Code: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response body: \(jsonString)")
            }
            throw PollError.serverError(httpResponse.statusCode)
        }
    }
}

struct PollResultsResponse: Codable {
    let success: Bool
    let poll: Poll
}

struct VotePollResponse: Codable {
    let success: Bool
    let poll: Poll
}

enum PollError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "Не авторизован"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        }
    }
}
