//
//  ConversationListView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import Combine

struct ConversationListView: View {
    @StateObject private var viewModel = ConversationListViewModel()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var messageListener = MessageListenerService.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showNewChat = false
    @State private var navigationPath = NavigationPath()
    @State private var scrollToMessageID: String? = nil
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    VStack {
                        ProgressView()
                        Text("Loading conversations...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }
                } else if viewModel.conversations.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.blue.opacity(0.5))
                        
                        Text("No Conversations Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start chatting with your team by tapping the + button")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button {
                            showNewChat = true
                        } label: {
                            Label("Start New Chat", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Conversation list
                    VStack(spacing: 0) {
                        // Network status indicator (only show if offline AND no data loaded)
                        // This prevents false positives in simulators
                        if !networkMonitor.isConnected && viewModel.conversations.isEmpty && !viewModel.isLoading {
                            HStack {
                                Image(systemName: "wifi.slash")
                                    .foregroundStyle(.white)
                                Text("Offline - Messages will send when reconnected")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                        }
                        
                        // Current user indicator - compact at top
                        if let user = authManager.user {
                            CurrentUserBadge(displayName: user.displayName, email: user.email)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                        }
                        
                        List {
                            ForEach(viewModel.conversations) { conversation in
                                NavigationLink(value: conversation) {
                                    ConversationRow(
                                        conversation: conversation,
                                        currentUserID: authManager.currentUserID
                                    )
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                deleteConversations(at: indexSet)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            await viewModel.fetchConversations()
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationDestination(for: Conversation.self) { conversation in
                ChatView(conversation: conversation, scrollToMessageID: scrollToMessageID)
                    .onAppear {
                        // Clear scroll target after navigation
                        scrollToMessageID = nil
                    }
            }
            .toolbar {
                // Current user indicator (top center)
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Chats")
                            .font(.headline)
                        if let user = authManager.user {
                            Text(user.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            try? await authManager.signOut()
                        }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
            }
            .onAppear {
                viewModel.startListening()
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .onChange(of: viewModel.conversations) { oldValue, newValue in
                // Start listening for new messages when conversations load
                if let userID = authManager.currentUserID {
                    messageListener.startListening(userID: userID, conversations: newValue)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { notification in
                handleDeepLink(notification)
            }
        }
    }
    
    private func handleDeepLink(_ notification: Notification) {
        guard let conversationID = notification.userInfo?["conversationID"] as? String else {
            print("⚠️ No conversationID in notification")
            return
        }
        
        // Extract optional messageID
        let messageID = notification.userInfo?["messageID"] as? String
        
        print("🔗 Deep link: Opening conversation \(conversationID)")
        if let messageID = messageID {
            print("🔗 Will scroll to message: \(messageID)")
            scrollToMessageID = messageID
        }
        
        // Find the conversation in our list
        if let conversation = viewModel.conversations.first(where: { $0.id == conversationID }) {
            // Navigate to the conversation
            navigationPath.append(conversation)
            print("✅ Navigated to conversation: \(conversation.name ?? "Unknown")")
        } else {
            print("⚠️ Conversation \(conversationID) not found in list")
        }
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = viewModel.conversations[index]
            Task {
                await viewModel.deleteConversation(conversation)
            }
        }
    }
}

#Preview {
    ConversationListView()
}

