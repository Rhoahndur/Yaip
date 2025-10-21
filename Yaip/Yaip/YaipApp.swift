//
//  YaipApp.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import FirebaseCore
import SwiftData

@main
struct YaipApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize LocalStorageManager (SwiftData)
        _ = LocalStorageManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase, newPhase)
        }
    }
    
    private func handleScenePhaseChange(_ oldPhase: ScenePhase, _ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("📱 App became active")
            // Sync pending messages when coming back online
            Task {
                await syncPendingMessages()
            }
        case .inactive:
            print("📱 App became inactive")
        case .background:
            print("📱 App went to background")
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
