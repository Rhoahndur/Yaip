//
//  ChatView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var authManager = AuthManager.shared
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingDetail = false
    @State private var otherUserStatus: UserStatus = .offline
    @State private var otherUserLastSeen: Date?
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self._viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.isLoading && viewModel.messages.isEmpty {
                            ProgressView()
                                .padding()
                        } else if viewModel.messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                
                                Text("No messages yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("Send a message to start the conversation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            ForEach(viewModel.messages) { message in
                                if conversation.type == .group {
                                    GroupMessageBubble(
                                        message: message,
                                        senderName: viewModel.getSenderName(for: message.senderID),
                                        isFromCurrentUser: message.senderID == authManager.currentUserID
                                    )
                                    .id(message.id)
                                } else {
                                    MessageBubble(
                                        message: message,
                                        isFromCurrentUser: message.senderID == authManager.currentUserID
                                    )
                                    .id(message.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages.count) { oldValue, newValue in
                    // Auto-scroll to bottom when new message arrives
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Scroll to bottom on appear
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Typing indicator
            if viewModel.otherUserIsTyping {
                TypingIndicator(userName: conversation.name ?? "Someone")
                    .transition(.opacity)
            }
            
            // Message composer
            MessageComposer(
                text: $viewModel.messageText,
                selectedImage: $viewModel.selectedImage
            ) {
                Task {
                    await viewModel.sendMessage()
                }
            }
        }
        .navigationTitle(conversation.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(conversation.name ?? "Chat")
                        .font(.headline)
                    
                    // Show online status for 1-on-1 chats
                    if conversation.type == .oneOnOne {
                        OnlineStatusText(status: otherUserStatus, lastSeen: otherUserLastSeen)
                    } else {
                        Text("\(conversation.participants.count) participants")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingDetail = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            ChatDetailView(conversation: conversation)
        }
        .onAppear {
            viewModel.startListening()
            viewModel.markAsRead()
            
            // Load online status for 1-on-1 chats
            if conversation.type == .oneOnOne {
                Task {
                    await loadOtherUserStatus()
                }
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isTextFieldFocused = false
        }
    }
    
    private func loadOtherUserStatus() async {
        guard let currentUserID = authManager.currentUserID,
              let otherUserID = conversation.participants.first(where: { $0 != currentUserID }) else {
            return
        }
        
        do {
            let user = try await UserService.shared.fetchUser(id: otherUserID)
            otherUserStatus = user.status
            otherUserLastSeen = user.lastSeen
        } catch {
            print("Error loading user status: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: Conversation(
            id: "1",
            type: .oneOnOne,
            participants: ["user1", "user2"],
            name: "John Doe",
            imageURL: nil,
            lastMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            unreadCount: [:]
        ))
    }
}

