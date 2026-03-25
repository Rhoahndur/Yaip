//
//  ProfileSetupView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var authManager = AuthManager.shared

    @State private var displayName = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    private var isNameValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                    }

                Text("Complete Your Profile")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Confirm your display name to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Enter your name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    saveProfile()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Get Started")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isNameValid ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(!isNameValid || isLoading)
            }
            .padding(.vertical, 40)
            .navigationTitle("Welcome!")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let name = authManager.user?.displayName, !name.isEmpty {
                    displayName = name
                }
            }
        }
    }

    private func saveProfile() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = ""
        isLoading = true

        guard let userID = authManager.currentUserID else {
            errorMessage = "Not signed in. Please try again."
            isLoading = false
            return
        }

        Task {
            do {
                try await UserService.shared.updateDisplayName(userID: userID, displayName: trimmed)
                authManager.refreshCurrentUser()
                authManager.completeProfileSetup()
            } catch {
                errorMessage = "Failed to save profile. Please try again."
                print("❌ Profile setup error: \(error)")
            }
            isLoading = false
        }
    }
}

#Preview {
    ProfileSetupView()
}

