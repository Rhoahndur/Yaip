//
//  MessageComposer.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct MessageComposer: View {
    @Binding var text: String
    @Binding var selectedImage: UIImage?
    let onSend: () -> Void
    
    @State private var showImagePreview = false
    @State private var imageCaption = ""
    @State private var pendingImage: UIImage?
    
    init(text: Binding<String>, selectedImage: Binding<UIImage?>, onSend: @escaping () -> Void) {
        self._text = text
        self._selectedImage = selectedImage
        self.onSend = onSend
        print("💬 MessageComposer initialized")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 12) {
                // Image picker button
                ImagePicker(selectedImage: $selectedImage)
                    .accessibilityLabel("Attach photo")
                    .accessibilityHint("Double tap to choose a photo to send")

                // Text field
                TextField("Message", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("Message input")
                    .accessibilityIdentifier("messageTextField")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .onChange(of: text) { oldValue, newValue in
                        if !newValue.isEmpty {
                            print("⌨️ Text changed: '\(newValue)'")
                        }
                    }
                    .onSubmit {
                        print("⌨️ Enter key pressed!")
                        if canSend {
                            print("✅ Triggering send via Enter key")
                            onSend()
                        } else {
                            print("⚠️ Cannot send - empty message")
                        }
                    }
                
                // Send button
                Button {
                    print("🔵 Send button tapped! canSend: \(canSend)")
                    onSend()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? .blue : .gray)
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
                .accessibilityIdentifier("sendButton")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))
        .onChange(of: selectedImage) { oldValue, newValue in
            // When image is selected, show preview modal
            if let image = newValue {
                pendingImage = image
                imageCaption = text // Pre-fill with any text already typed
                showImagePreview = true
            }
        }
        .sheet(isPresented: $showImagePreview) {
            if let image = pendingImage {
                ImagePreviewModal(
                    image: image,
                    caption: $imageCaption,
                    onSend: {
                        // Update text with caption and keep image
                        text = imageCaption
                        selectedImage = pendingImage
                        // Trigger send
                        onSend()
                        // Reset
                        imageCaption = ""
                        pendingImage = nil
                    }
                )
            }
        }
        .onChange(of: showImagePreview) { oldValue, newValue in
            // If modal was dismissed without sending, clear the selected image
            if !newValue && selectedImage != nil && pendingImage != nil {
                selectedImage = nil
                pendingImage = nil
                imageCaption = ""
            }
        }
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }
}

#Preview {
    VStack {
        Spacer()
        MessageComposer(
            text: .constant(""),
            selectedImage: .constant(nil),
            onSend: {}
        )
    }
}

