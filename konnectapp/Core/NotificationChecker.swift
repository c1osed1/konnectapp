import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
class NotificationChecker: ObservableObject {
    static let shared = NotificationChecker()
    
    @Published var lastNotificationId: Int64?
    private var checkTimer: Timer?
    
    private init() {
        requestNotificationPermission()
    }
    
    func startChecking() {
        stopChecking()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNewNotifications()
            }
        }
        RunLoop.main.add(checkTimer!, forMode: .common)
        Task { @MainActor in
            await checkForNewNotifications()
        }
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
        do {
            let response = try await NotificationService.shared.getNotifications()
            
            if let firstNotification = response.notifications.first {
                if let lastId = lastNotificationId {
                    if firstNotification.id > lastId && (firstNotification.is_read == false || firstNotification.is_read == nil) {
                        showLocalNotification(for: firstNotification)
                        lastNotificationId = firstNotification.id
                    }
                } else {
                    if firstNotification.is_read == false || firstNotification.is_read == nil {
                        showLocalNotification(for: firstNotification)
                    }
                    lastNotificationId = firstNotification.id
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
            let senderName = sender.name ?? sender.username
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

