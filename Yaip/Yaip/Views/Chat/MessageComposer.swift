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
    
    init(text: Binding<String>, selectedImage: Binding<UIImage?>, onSend: @escaping () -> Void) {
        self._text = text
        self._selectedImage = selectedImage
        self.onSend = onSend
        print("💬 MessageComposer initialized")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image preview
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button {
                        selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            
            HStack(spacing: 12) {
                // Image picker button
                ImagePicker(selectedImage: $selectedImage)
                
                // Text field
                TextField("Message", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))
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

