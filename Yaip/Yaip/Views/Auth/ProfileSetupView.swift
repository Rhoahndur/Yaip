//
//  ProfileSetupView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI
import Combine

struct ProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    @State private var displayName = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Profile Image Placeholder
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
                
                // Display Name Field
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
                
                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Continue Button
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
                .background(displayName.isEmpty ? Color.gray : Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(displayName.isEmpty || isLoading)
            }
            .padding(.vertical, 40)
            .navigationTitle("Welcome!")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveProfile() {
        errorMessage = ""
        isLoading = true
        
        // In a real implementation, you'd update the Firestore user document here
        // For now, we'll just dismiss since the user is already created
        
        Task {
            // Simulate API call
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    ProfileSetupView()
}

