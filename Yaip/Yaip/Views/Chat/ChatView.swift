//
//  ChatView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let conversation: Conversation
    let scrollToMessageID: String?
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var aiViewModel: AIFeaturesViewModel
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingDetail = false
    @State private var otherUserStatus: UserStatus = .offline
    @State private var otherUserLastSeen: Date?
    @State private var statusListener: ListenerRegistration?
    @State private var hasScrolledToTarget = false
    @State private var displayName: String = ""
    @State private var highlightedMessageID: String?
    @State private var shouldAnimateHighlight = false
    @State private var scrollProxy: ScrollViewProxy?

    init(conversation: Conversation, scrollToMessageID: String? = nil) {
        self.conversation = conversation
        self.scrollToMessageID = scrollToMessageID
        self._viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
        self._aiViewModel = StateObject(wrappedValue: AIFeaturesViewModel(conversationID: conversation.id ?? ""))
    }

    // Check if any AI feature is currently processing
    private var isAIProcessing: Bool {
        aiViewModel.isLoadingSummary ||
        aiViewModel.isLoadingActionItems ||
        aiViewModel.isLoadingMeeting ||
        aiViewModel.isLoadingDecisions ||
        aiViewModel.isLoadingPriority ||
        aiViewModel.isSearching
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        Color.clear
                            .frame(height: 0)
                            .onAppear {
                                // Capture the scroll proxy for later use
                                scrollProxy = proxy
                            }
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
                                let isTargetMessage = message.id == scrollToMessageID || message.id == highlightedMessageID

                                if conversation.type == .group {
                                    GroupMessageBubble(
                                        message: message,
                                        senderName: viewModel.getSenderName(for: message.senderID),
                                        isFromCurrentUser: message.senderID == authManager.currentUserID,
                                        conversation: conversation,
                                        currentUserID: authManager.currentUserID ?? "",
                                        onRetry: {
                                            Task {
                                                await viewModel.retryMessage(message)
                                            }
                                        }
                                    )
                                    .id(message.id)
                                    .background(
                                        isTargetMessage ? Color.yellow.opacity(0.3) : Color.clear
                                    )
                                    .animation(.easeInOut(duration: 1.5).repeatCount(2, autoreverses: true), value: shouldAnimateHighlight)
                                } else {
                                    MessageBubble(
                                        message: message,
                                        isFromCurrentUser: message.senderID == authManager.currentUserID,
                                        onRetry: {
                                            Task {
                                                await viewModel.retryMessage(message)
                                            }
                                        }
                                    )
                                    .id(message.id)
                                    .background(
                                        isTargetMessage ? Color.yellow.opacity(0.3) : Color.clear
                                    )
                                    .animation(.easeInOut(duration: 1.5).repeatCount(2, autoreverses: true), value: shouldAnimateHighlight)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages.count) { oldValue, newValue in
                    // If we have a target message to scroll to, do that first
                    if let targetID = scrollToMessageID, !hasScrolledToTarget {
                        if viewModel.messages.contains(where: { $0.id == targetID }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    proxy.scrollTo(targetID, anchor: .center)
                                }
                                hasScrolledToTarget = true
                                print("📍 Scrolled to target message: \(targetID)")
                            }
                        }
                    } else {
                        // Auto-scroll to bottom when new message arrives (normal behavior)
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onAppear {
                    // If we have a target message, scroll to it, otherwise scroll to bottom
                    if let targetID = scrollToMessageID {
                        print("🎯 Target message ID: \(targetID)")
                        // Wait for messages to load, then scroll
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if viewModel.messages.contains(where: { $0.id == targetID }) {
                                withAnimation {
                                    proxy.scrollTo(targetID, anchor: .center)
                                }
                                hasScrolledToTarget = true
                                print("📍 Scrolled to target message on appear: \(targetID)")
                            } else {
                                print("⚠️ Target message not found in loaded messages")
                            }
                        }
                    } else {
                        // Normal behavior: scroll to bottom
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
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
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(displayName)
                        .font(.headline)
                    
                    // Show online status for 1-on-1 chats (only if we're online)
                    if conversation.type == .oneOnOne {
                        if networkMonitor.isConnected {
                            OnlineStatusText(status: otherUserStatus, lastSeen: otherUserLastSeen)
                        } else {
                            Text("Status unavailable")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
                HStack(spacing: 12) {
                    // AI Features Menu
                    Menu {
                        Section("AI Assistant") {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                aiViewModel.summarizeThread()
                            } label: {
                                Label("Summarize Thread", systemImage: "doc.text.magnifyingglass")
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                aiViewModel.extractActionItems()
                            } label: {
                                Label("Extract Action Items", systemImage: "checkmark.circle")
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                aiViewModel.suggestMeetingTimes()
                            } label: {
                                Label("Suggest Meeting Times", systemImage: "calendar.badge.clock")
                            }
                        }

                        Section("Intelligence") {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                aiViewModel.extractDecisions()
                            } label: {
                                Label("View Decisions", systemImage: "lightbulb")
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                aiViewModel.detectPriority()
                            } label: {
                                Label("Detect Priority Messages", systemImage: "exclamationmark.triangle")
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                aiViewModel.showSearch = true
                            } label: {
                                Label("Smart Search", systemImage: "magnifyingglass")
                            }
                        }
                    } label: {
                        ZStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                                .scaleEffect(isAIProcessing ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAIProcessing)

                            // Show pulsing badge if AI is processing
                            if isAIProcessing {
                                Circle()
                                    .fill(.purple)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                                    .scaleEffect(isAIProcessing ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAIProcessing)
                            }
                        }
                    }

                    Button {
                        showingDetail = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            ChatDetailView(conversation: conversation)
        }
        // AI Feature Sheets
        .sheet(isPresented: $aiViewModel.showSummary) {
            ThreadSummaryView(viewModel: aiViewModel)
        }
        .sheet(isPresented: $aiViewModel.showActionItems) {
            ActionItemsView(viewModel: aiViewModel) { messageID in
                scrollToMessage(messageID)
            }
        }
        .sheet(isPresented: $aiViewModel.showMeetingSuggestion) {
            MeetingSuggestionsView(viewModel: aiViewModel)
        }
        .sheet(isPresented: $aiViewModel.showDecisions) {
            DecisionTrackingView(viewModel: aiViewModel) { messageID in
                scrollToMessage(messageID)
            }
        }
        .sheet(isPresented: $aiViewModel.showPriority) {
            PriorityMessagesView(viewModel: aiViewModel) { messageID in
                scrollToMessage(messageID)
            }
        }
        .sheet(isPresented: $aiViewModel.showSearch) {
            SmartSearchView(viewModel: aiViewModel) { messageID in
                scrollToMessage(messageID)
            }
        }
        .overlay(alignment: .top) {
            if isAIProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)

                    Text("AI is processing...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.purple)
                .cornerRadius(20)
                .shadow(radius: 4)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: isAIProcessing)
            }
        }
        .networkStateBanner()
        .onNetworkReconnect {
            await viewModel.retryAllFailedMessages()
            
            // Reload user status for 1-on-1 chats
            if conversation.type == .oneOnOne {
                await loadOtherUserStatus()
            }
        }
        .onAppear {
            // Load conversation name first
            loadConversationName()
            
            viewModel.startListening()
            viewModel.markAsRead()
            
            // Tell MessageListenerService we're viewing this conversation
            // This suppresses notifications for messages in this chat
            MessageListenerService.shared.setCurrentlyViewing(conversationID: conversation.id)
            
            // Load online status for 1-on-1 chats
            if conversation.type == .oneOnOne {
                Task {
                    await loadOtherUserStatus()
                }
            }
            
            // Retry any failed messages when view appears and we're online
            if networkMonitor.isConnected {
                Task {
                    await viewModel.retryAllFailedMessages()
                }
            }
        }
        .onDisappear {
            viewModel.stopListening()
            
            // Tell MessageListenerService we're no longer viewing this conversation
            MessageListenerService.shared.setCurrentlyViewing(conversationID: nil)
            
            // Clean up status listener
            statusListener?.remove()
            statusListener = nil
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isTextFieldFocused = false
        }
    }
    
    // Helper function to scroll to and highlight a message
    private func scrollToMessage(_ messageID: String) {
        guard let proxy = scrollProxy else { return }

        // Set the highlighted message
        highlightedMessageID = messageID

        // Scroll to the message
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo(messageID, anchor: .center)
        }

        // Trigger highlight animation
        shouldAnimateHighlight.toggle()

        // Clear highlight after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            highlightedMessageID = nil
        }
    }

    private func loadConversationName() {
        if conversation.type == .group {
            // For group chats, use the group name
            displayName = conversation.name ?? "Group Chat"
        } else {
            // For 1-on-1, fetch the other user's name
            displayName = "Loading..."
            Task {
                guard let currentUserID = authManager.currentUserID,
                      let otherUserID = conversation.participants.first(where: { $0 != currentUserID }) else {
                    displayName = "Chat"
                    return
                }
                
                do {
                    let otherUser = try await UserService.shared.fetchUser(id: otherUserID)
                    await MainActor.run {
                        displayName = otherUser.displayName
                    }
                } catch {
                    print("Error loading other user's name: \(error)")
                    await MainActor.run {
                        displayName = "Chat"
                    }
                }
            }
        }
    }
    
    private func loadOtherUserStatus() async {
        guard let currentUserID = authManager.currentUserID,
              let otherUserID = conversation.participants.first(where: { $0 != currentUserID }) else {
            return
        }
        
        // First, fetch initial user data
        do {
            let user = try await UserService.shared.fetchUser(id: otherUserID)
            otherUserStatus = user.status
            otherUserLastSeen = user.lastSeen
        } catch {
            print("Error loading user status: \(error)")
        }
        
        // 🔥 Set up real-time status listener
        setupStatusListener(for: otherUserID)
    }
    
    private func setupStatusListener(for userID: String) {
        // Remove any existing listener
        statusListener?.remove()
        
        // Set up real-time listener for user status
        statusListener = PresenceService.shared.listenToPresence(userID: userID) { status, lastSeen in
            DispatchQueue.main.async {
                self.otherUserStatus = status
                if let lastSeen = lastSeen {
                    self.otherUserLastSeen = lastSeen
                }
            }
        }
        
        print("🔔 Real-time status listener started in ChatView for user: \(userID)")
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

