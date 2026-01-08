import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
class NotificationChecker: ObservableObject {
    static let shared = NotificationChecker()
    
    @Published var lastNotificationId: Int64?
    @Published var unreadCount: Int = 0
    private var checkTimer: Timer?
    private var isAppActive: Bool = true
    private var lastCheckTime: Date?
    private var isChecking: Bool = false
    
    private init() {
        requestNotificationPermission()
        setupAppStateObservers()
    }
    
    private func setupAppStateObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.isAppActive = true
                self?.startChecking()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.isAppActive = false
                self?.stopChecking()
            }
        }
    }
    
    func startChecking() {
        guard isAppActive else { return }
        guard !isChecking else {
            print("🔵 NotificationChecker: Already checking, skipping duplicate start")
            return
        }
        stopChecking()
        
        let timeSinceLastCheck = lastCheckTime.map { Date().timeIntervalSince($0) } ?? 0
        let delay = max(0, 30.0 - timeSinceLastCheck)
        
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                Task { @MainActor in
                    await self?.checkForNewNotifications()
                    self?.scheduleNextCheck()
                }
            }
        } else {
            Task { @MainActor in
                await checkForNewNotifications()
                scheduleNextCheck()
            }
        }
    }
    
    private func scheduleNextCheck() {
        guard isAppActive else { return }
        checkTimer?.invalidate()
        
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNewNotifications()
                self?.scheduleNextCheck()
            }
        }
        RunLoop.main.add(checkTimer!, forMode: .common)
    }
    
    func stopChecking() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error)")
            } else {
                print("✅ Notification permission granted: \(granted)")
            }
        }
    }
    
    private func checkForNewNotifications() async {
        guard isAppActive else { return }
        guard !isChecking else {
            print("🔵 NotificationChecker: Check already in progress, skipping")
            return
        }
        
        isChecking = true
        defer { isChecking = false }
        
        do {
            let response = try await NotificationService.shared.getNotifications()
            
            await MainActor.run {
                unreadCount = response.unread_count ?? 0
                lastCheckTime = Date()
            }
            
            if let firstNotification = response.notifications.first {
                if let lastId = lastNotificationId {
                    if firstNotification.id > lastId && (firstNotification.is_read == false || firstNotification.is_read == nil) {
                        showLocalNotification(for: firstNotification)
                        await MainActor.run {
                            lastNotificationId = firstNotification.id
                        }
                    }
                } else {
                    if firstNotification.is_read == false || firstNotification.is_read == nil {
                        showLocalNotification(for: firstNotification)
                    }
                    await MainActor.run {
                        lastNotificationId = firstNotification.id
                    }
                }
            }
        } catch {
            print("❌ Error checking notifications: \(error)")
        }
    }
    
    private func showLocalNotification(for notification: Notification) {
        let content = UNMutableNotificationContent()
        content.title = notificationTypeTitle(notification.type)
        
        let messageBody: String
        if let sender = notification.sender_user {
            let senderName: String
            if let name = sender.name, !name.isEmpty {
                senderName = name
            } else {
                senderName = sender.username
            }
            messageBody = "\(senderName) \(notification.message)"
        } else {
            messageBody = notification.message
        }
        content.body = messageBody
        content.sound = .default
        
        if let sender = notification.sender_user {
            content.userInfo = [
                "notificationId": notification.id,
                "link": notification.link ?? "",
                "senderUsername": sender.username
            ]
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "notification_\(notification.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error showing notification: \(error)")
            }
        }
    }
    
    private func notificationTypeTitle(_ type: String) -> String {
        switch type {
        case "post_like": return "Лайк на пост"
        case "comment": return "Новый комментарий"
        case "reply": return "Ответ на комментарий"
        case "comment_like": return "Лайк на комментарий"
        case "reply_like": return "Лайк на ответ"
        default: return "Уведомление"
        }
    }
}

