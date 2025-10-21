//
//  WelcomeView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showSignUp = false
    @State private var showLogin = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Logo/Branding
            Image(systemName: "message.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            
            Text("Yaip")
                .font(.system(size: 48, weight: .bold))
            
            Text("AI-powered messaging for remote teams")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    showSignUp = true
                } label: {
                    Text("Sign Up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    showLogin = true
                } label: {
                    Text("Log In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundStyle(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
}

#Preview {
    WelcomeView()
}

