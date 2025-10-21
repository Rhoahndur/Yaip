//
//  ErrorView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

struct ErrorView: View {
    var message: String
    var retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let retryAction = retryAction {
                Button {
                    retryAction()
                } label: {
                    Text("Try Again")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 44)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    ErrorView(
        message: "Unable to load messages. Please check your internet connection.",
        retryAction: { print("Retry tapped") }
    )
}

