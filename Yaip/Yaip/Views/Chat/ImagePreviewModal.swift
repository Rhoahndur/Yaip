//
//  ImagePreviewModal.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/23/25.
//

import SwiftUI

/// Modal to preview image and add caption before sending
struct ImagePreviewModal: View {
    let image: UIImage
    @Binding var caption: String
    @Environment(\.dismiss) private var dismiss
    var onSend: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image preview
                ScrollView {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                }
                .frame(maxHeight: .infinity)
                
                Divider()
                
                // Caption input
                HStack(spacing: 12) {
                    TextField("Add a caption...", text: $caption, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(1...5)
                        .focused($isTextFieldFocused)
                    
                    Button {
                        onSend()
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Send Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Auto-focus the text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

#Preview {
    ImagePreviewModal(
        image: UIImage(systemName: "photo")!,
        caption: .constant(""),
        onSend: {}
    )
}

