//
//  LoginView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Account")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await login()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if authManager.isLoading {
                                ProgressView()
                            } else {
                                Text("Log In")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                    
                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Log In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email", text: $email)
                Button("Send Reset Link") {
                    Task {
                        await resetPassword()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your email to receive a password reset link")
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() async {
        errorMessage = nil
        
        do {
            try await authManager.signIn(email: email, password: password)
            
            // Wait a bit for auth state to update before dismissing
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if actually authenticated before dismissing
            if authManager.isAuthenticated {
                dismiss()
            } else {
                errorMessage = "Login failed. Please try again."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func resetPassword() async {
        guard !email.isEmpty else { return }
        
        do {
            try await authManager.resetPassword(email: email)
            errorMessage = "Password reset link sent to \(email)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
}

