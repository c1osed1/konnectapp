import Foundation
import SwiftUI
import Combine

class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()
    
    @Published var navigationPath = NavigationPath()
    @Published var targetUsername: String?
    @Published var targetPostId: Int64?
    @Published var targetTrackId: Int64?
    
    private init() {}
    
    func handleURL(_ url: URL) {
        guard url.host == "k-connect.ru" || url.host == "www.k-connect.ru" else { return }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        if pathComponents.count >= 2 {
            let type = pathComponents[0]
            let identifier = pathComponents[1]
            
            switch type {
            case "user", "profile":
                targetUsername = identifier
            case "post", "posts":
                if let postId = Int64(identifier) {
                    targetPostId = postId
                }
            case "music":
                if let trackId = Int64(identifier) {
                    targetTrackId = trackId
                }
            default:
                break
            }
        } else if pathComponents.count == 1 {
            let identifier = pathComponents[0]
            if let username = identifier.components(separatedBy: "@").last, !username.isEmpty {
                targetUsername = username
            }
        }
    }
}

