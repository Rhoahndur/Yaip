//
//  ConversationListView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct ConversationListView: View {
    @StateObject private var viewModel = ConversationListViewModel()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var messageListener = MessageListenerService.shared
    @State private var showNewChat = false
    @State private var hasRequestedNotifications = false
    
    var body: some View {
        NavigationStack {
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
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(value: conversation) {
                                ConversationRow(
                                    conversation: conversation,
                                    currentUserID: authManager.currentUserID
                                )
                            }
                        }
                        .onDelete { indexSet in
                            deleteConversations(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchConversations()
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationDestination(for: Conversation.self) { conversation in
                ChatView(conversation: conversation)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        try? authManager.signOut()
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
                
                // Request local notification permission on first appearance
                if !hasRequestedNotifications {
                    hasRequestedNotifications = true
                    Task {
                        do {
                            try await LocalNotificationManager.shared.requestAuthorization()
                        } catch {
                            print("❌ Failed to request notification authorization: \(error)")
                        }
                    }
                }
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

