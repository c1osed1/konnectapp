//
//  konnectappApp.swift
//  konnectapp
//
//  Created by qsoul on 05.01.2026.
//

import SwiftUI

@main
struct konnectappApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
