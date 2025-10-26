//
//  ProfileSettingsView.swift
//  Yaip
//
//  Edit user profile (display name and photo)
//

import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isUploading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    // Profile photo
                    Button {
                        showImagePicker = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let profileImageURL = authManager.currentUser?.profileImageURL,
                                      let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    defaultProfileImage
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                            } else {
                                defaultProfileImage
                            }

                            // Edit icon
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 16))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    if isUploading {
                        ProgressView("Uploading photo...")
                            .font(.caption)
                    }
                }
            }

            Section("Display Name") {
                TextField("Display Name", text: $displayName)
                    .textInputAutocapitalization(.words)
                    .disabled(isSaving)
            }

            Section("Account") {
                LabeledContent("Email", value: authManager.currentUser?.email ?? "")
                    .foregroundStyle(.secondary)

                LabeledContent("User ID", value: authManager.currentUserID ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    saveProfile()
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || isUploading || !hasChanges)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert("Profile Updated", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been updated successfully.")
        }
        .onAppear {
            loadCurrentProfile()
        }
        .onChange(of: selectedImage) { _, newImage in
            if newImage != nil {
                uploadProfilePhoto()
            }
        }
    }

    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay(
                Text(displayName.prefix(1).uppercased())
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.blue)
            )
    }

    private var hasChanges: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return displayName != currentUser.displayName || selectedImage != nil
    }

    private func loadCurrentProfile() {
        if let currentUser = authManager.currentUser {
            displayName = currentUser.displayName
        }
    }

    private func uploadProfilePhoto() {
        guard let image = selectedImage,
              let userID = authManager.currentUserID else { return }

        isUploading = true
        errorMessage = nil

        Task {
            do {
                let photoURL = try await StorageService.shared.uploadProfileImage(image, userID: userID)

                // Update Firestore
                try await UserService.shared.updateProfilePhoto(userID: userID, photoURL: photoURL)

                // Update local user object
                authManager.refreshCurrentUser()

                await MainActor.run {
                    isUploading = false
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                }
            }
        }
    }

    private func saveProfile() {
        guard let userID = authManager.currentUserID else { return }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                // Update display name if changed
                if displayName != authManager.currentUser?.displayName {
                    try await UserService.shared.updateDisplayName(userID: userID, displayName: displayName)
                }

                // Refresh current user data
                authManager.refreshCurrentUser()

                await MainActor.run {
                    isSaving = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
}
