//
//  ContentView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Show main app (conversation list)
                ConversationListView()
            } else {
                // Show authentication flow
                WelcomeView()
            }
        }
        .withInAppBanner() // Add in-app banner overlay
    }
}

#Preview {
    ContentView()
}
