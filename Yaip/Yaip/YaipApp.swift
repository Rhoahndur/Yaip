//
//  YaipApp.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import FirebaseCore
import SwiftData
import GoogleSignIn

@main
struct YaipApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    init() {
        // Initialize Firebase
        FirebaseApp.configure()

        // Initialize LocalStorageManager (SwiftData)
        _ = LocalStorageManager.shared

        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .onOpenURL { url in
                handleOAuthURL(url)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase, newPhase)
        }
    }
    
    private func handleOAuthURL(_ url: URL) {
        print("🔗 Received URL: \(url)")

        // Check if it's a Google Sign-In URL
        if GIDSignIn.sharedInstance.handle(url) {
            print("✅ URL handled by Google Sign-In")
            return
        }

        // TODO: Add Microsoft MSAL URL handling when Outlook integration is added
        // if url.scheme?.hasPrefix("msauth") == true {
        //     MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: nil)
        //     print("✅ URL handled by MSAL")
        //     return
        // }

        print("⚠️ URL not recognized by any OAuth provider")
    }

    private func handleScenePhaseChange(_ oldPhase: ScenePhase, _ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("📱 App became active")
            // Clear badge count when user opens app
            LocalNotificationManager.shared.clearBadge()
            
            // Set user to ONLINE when app becomes active
            if let userID = authManager.currentUserID {
                Task {
                    do {
                        try await PresenceService.shared.setOnline(userID: userID)
                        print("🟢 User set to ONLINE")
                    } catch {
                        print("❌ Failed to set user online: \(error)")
                    }
                }
            }
            
            // Sync pending messages when coming back online
            Task {
                await syncPendingMessages()
            }
            
        case .inactive:
            print("📱 App became inactive")
            // Don't change status on inactive - it's a brief transition
            
        case .background:
            print("📱 App went to background")
            
            // Set user to AWAY when app goes to background
            if let userID = authManager.currentUserID {
                Task {
                    do {
                        try await PresenceService.shared.updateStatus(.away, for: userID)
                        print("🟠 User set to AWAY")
                    } catch {
                        print("❌ Failed to set user away: \(error)")
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    private func syncPendingMessages() async {
        // Try to send any pending messages
        do {
            let pendingMessages = try LocalStorageManager.shared.getPendingMessages()
            print("📤 Found \(pendingMessages.count) pending messages to sync")
            
            for message in pendingMessages {
                do {
                    try await MessageService.shared.sendMessage(message)
                    try? LocalStorageManager.shared.markMessageSynced(id: message.id ?? "")
                    print("✅ Synced message: \(message.id ?? "")")
                } catch {
                    print("❌ Failed to sync message: \(error)")
                }
            }
        } catch {
            print("❌ Error getting pending messages: \(error)")
        }
    }
}
