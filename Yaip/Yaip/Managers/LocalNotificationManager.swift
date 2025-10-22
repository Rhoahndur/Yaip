//
//  LocalNotificationManager.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import Foundation
import UserNotifications
import FirebaseFirestore
import Combine

/// Manages local notifications (no APNs required!)
@MainActor
class LocalNotificationManager: NSObject, ObservableObject {
    static let shared = LocalNotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    /// Request notification permission from user
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await notificationCenter.requestAuthorization(options: options)
        
        // Update authorization status
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        
        print("🔔 Local notification permission granted: \(granted)")
    }
    
    /// Send a local notification for a new message
    func sendMessageNotification(
        conversationID: String,
        messageID: String,
        senderName: String,
        messageText: String,
        isGroup: Bool,
        groupName: String?,
        totalUnreadCount: Int
    ) async {
        // Check permission
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("⚠️ Notification permission not granted")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        
        if isGroup, let groupName = groupName {
            content.title = "\(senderName) in \(groupName)"
        } else {
            content.title = senderName
        }
        
        content.body = messageText.isEmpty ? "📷 Sent a photo" : messageText
        content.sound = .default
        
        // Set badge to actual unread count (cap at 99)
        let badgeCount = min(totalUnreadCount, 99)
        content.badge = NSNumber(value: badgeCount)
        print("🔢 Setting badge count to: \(badgeCount)")
        
        // Add conversation ID and message ID to userInfo for handling tap
        content.userInfo = [
            "conversationID": conversationID,
            "messageID": messageID,
            "type": "new_message"
        ]
        
        // Create trigger (immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create request with unique ID
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Add notification
        do {
            try await notificationCenter.add(request)
            print("✅ Local notification sent: \(senderName)")
        } catch {
            print("❌ Error sending local notification: \(error)")
        }
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        print("🧹 Cleared all notifications")
    }
    
    /// Clear badge count
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocalNotificationManager: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in FOREGROUND
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        print("🔔 Received local notification in foreground:")
        print("   Title: \(notification.request.content.title)")
        print("   Body: \(notification.request.content.body)")
        print("   ℹ️  Suppressing system notification (using in-app banner instead)")
        
        // DON'T show system notification when app is in foreground
        // (We're using custom in-app banner instead)
        // The notification WILL show if user switches to another app
        completionHandler([])
    }
    
    /// Handle notification tap (when user taps on notification)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        print("👆 User tapped notification:")
        print("   UserInfo: \(userInfo)")
        
        if let conversationID = userInfo["conversationID"] as? String {
            let messageID = userInfo["messageID"] as? String
            print("   Opening conversation: \(conversationID)")
            if let messageID = messageID {
                print("   Scrolling to message: \(messageID)")
            }
            // Post notification for deep linking
            Task { @MainActor in
                var notificationUserInfo: [String: Any] = ["conversationID": conversationID]
                if let messageID = messageID {
                    notificationUserInfo["messageID"] = messageID
                }
                NotificationCenter.default.post(
                    name: .openConversation,
                    object: nil,
                    userInfo: notificationUserInfo
                )
            }
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openConversation = Notification.Name("openConversation")
}

