//
//  ProfilePhotoPickerSheet.swift
//  Yaip
//
//  Improved profile photo picker with camera, library, and paste options
//

import SwiftUI
import PhotosUI

struct ProfilePhotoPickerSheet: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showCropper = false
    @State private var imageToEdit: UIImage?
    @State private var hasPasteboardImage = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose how you'd like to add your profile photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section {
                    // Camera option
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Take Photo")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("Use your camera to take a selfie")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Photo Library option
                    Button {
                        showPhotoLibrary = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose from Library")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("Pick a photo from your gallery")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Paste option (only show if clipboard has image)
                    if hasPasteboardImage {
                        Button {
                            pasteFromClipboard()
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Paste from Clipboard")
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text("Use an image you copied")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(selectedImage: $imageToEdit)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker(selectedImage: $imageToEdit)
            }
            .sheet(isPresented: $showCropper) {
                if let image = imageToEdit {
                    ImageCropperView(image: image, croppedImage: $selectedImage)
                }
            }
            .onChange(of: imageToEdit) { _, newImage in
                if newImage != nil {
                    showCropper = true
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    dismiss()
                }
            }
            .onAppear {
                checkClipboardForImage()
            }
        }
    }

    private func checkClipboardForImage() {
        hasPasteboardImage = UIPasteboard.general.hasImages
    }

    private func pasteFromClipboard() {
        if let image = UIPasteboard.general.image {
            imageToEdit = image
        }
    }
}

// Camera Picker using UIImagePickerController
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .front // Default to front camera for selfies
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Photo Library Picker using PhotosUI
struct PhotoLibraryPicker: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)

                    Text("Choose a Photo")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Select a photo from your library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Photo Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        dismiss()
                    }
                }
            }
        }
    }
}

// Simple Image Cropper
struct ImageCropperView: View {
    let image: UIImage
    @Binding var croppedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            VStack {
                Text("Position and scale your photo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top)

                Spacer()

                // Crop area
                ZStack {
                    // Background
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    // Circular crop area
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 300, height: 300)
                        .overlay(
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(scale)
                                .offset(offset)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                }

                Spacer()

                // Instructions
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Label("Pinch to zoom", systemImage: "arrow.up.left.and.arrow.down.right")
                        Label("Drag to position", systemImage: "hand.draw")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Crop Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        cropImage()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func cropImage() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        let croppedUIImage = renderer.image { context in
            // Calculate the rect to draw
            let imageSize = image.size
            let scaledSize = CGSize(
                width: imageSize.width * scale,
                height: imageSize.height * scale
            )

            let x = (300 - scaledSize.width) / 2 + offset.width
            let y = (300 - scaledSize.height) / 2 + offset.height

            let drawRect = CGRect(
                x: x,
                y: y,
                width: scaledSize.width,
                height: scaledSize.height
            )

            // Clip to circle
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 300, height: 300))
            path.addClip()

            // Draw image
            image.draw(in: drawRect)
        }

        croppedImage = croppedUIImage
        dismiss()
    }
}

#Preview {
    ProfilePhotoPickerSheet(selectedImage: .constant(nil))
}
