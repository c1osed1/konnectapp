//
//  konnectappApp.swift
//  konnectapp
//
//  Created by qsoul on 05.01.2026.
//

import SwiftUI
import UserNotifications

@main
struct konnectappApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    
    init() {
        setupNotificationDelegate()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    deepLinkHandler.handleURL(url)
                }
        }
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let linkString = userInfo["link"] as? String, let link = URL(string: "https://k-connect.ru\(linkString)") {
            DeepLinkHandler.shared.handleURL(link)
        }
        
        completionHandler()
    }
}
