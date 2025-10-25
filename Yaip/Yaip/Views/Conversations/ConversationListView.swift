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
    @State private var showSettings = false
    @State private var showInviteFriends = false
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
                        // Current user indicator - compact at top
                        if let user = authManager.user {
                            CurrentUserBadge(displayName: user.displayName, email: user.email)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                        }
                        
                        List {
                            ForEach(viewModel.filteredConversations) { conversation in
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
                
                // Manual connectivity check button (only show when offline)
                if !networkMonitor.isConnected {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            print("👆 User manually triggered connectivity check")
                            networkMonitor.checkConnectionNow()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.orange)
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

                // Three-dot menu (Signal-style)
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        // Filter section
                        Section {
                            Button {
                                viewModel.toggleFilterUnread()
                            } label: {
                                Label(
                                    viewModel.showUnreadOnly ? "Show All Chats" : "Filter Unread",
                                    systemImage: viewModel.showUnreadOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
                                )
                            }

                            Button {
                                Task {
                                    await viewModel.markAllAsRead()
                                }
                            } label: {
                                Label("Mark All Read", systemImage: "checkmark.circle")
                            }
                            .disabled(viewModel.conversations.isEmpty)
                        }

                        // Social section
                        Section {
                            Button {
                                showInviteFriends = true
                            } label: {
                                Label("Invite Friends", systemImage: "person.2.fill")
                            }
                        }

                        // Settings
                        Section {
                            Button {
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showInviteFriends) {
                NavigationStack {
                    InviteFriendsView()
                }
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
            .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
                // Reload conversation details and user statuses when reconnecting
                if !oldValue && newValue {
                    Task {
                        await viewModel.fetchConversations()
                    }
                }
            }
        }
        .networkStateBanner()
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

