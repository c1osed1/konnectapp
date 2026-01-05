import Foundation
import Combine

class OnlineUsersViewModel: ObservableObject {
    @Published var onlineUsers: [PostUser] = []
    @Published var isLoading = false
    
    private var updateTimer: Timer?
    
    func startAutoUpdate() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task {
                await self?.loadOnlineUsers()
            }
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }
    
    func stopAutoUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func loadOnlineUsers() async {
        print("📥 Loading online users...")
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let users = try await OnlineUsersService.shared.getOnlineUsers(limit: 50)
            print("✅ Loaded \(users.count) online users")
            await MainActor.run {
                self.onlineUsers = users
                self.isLoading = false
            }
        } catch {
            print("❌ Error loading online users: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

