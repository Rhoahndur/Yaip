//
//  ContentView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var hasRequestedNotifications = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.needsProfileSetup {
                    ProfileSetupView()
                } else {
                    ConversationListView()
                }
            } else {
                WelcomeView()
            }
        }
        .withInAppBanner() // Add in-app banner overlay
        .onAppear {
            // Request notification permissions as soon as app loads
            if !hasRequestedNotifications {
                hasRequestedNotifications = true
                Task {
                    await requestNotificationPermissions()
                }
            }
        }
    }
    
    private func requestNotificationPermissions() async {
        do {
            print("🔔 Requesting notification permissions...")
            try await LocalNotificationManager.shared.requestAuthorization()
            
            // Check current permission status
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            print("🔔 Notification permission status: \(settings.authorizationStatus.rawValue)")
            
            switch settings.authorizationStatus {
            case .authorized:
                print("✅ Notifications AUTHORIZED - will work in background!")
            case .denied:
                print("❌ Notifications DENIED - user must enable in Settings app")
                print("   Go to: Settings > Yaip > Notifications")
            case .notDetermined:
                print("⚠️ Notifications not determined yet")
            case .provisional:
                print("⚠️ Notifications provisional")
            case .ephemeral:
                print("⚠️ Notifications ephemeral")
            @unknown default:
                print("⚠️ Unknown notification status")
            }
        } catch {
            print("❌ Failed to request notification permissions: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
