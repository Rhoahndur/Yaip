//
//  TypingIndicator.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct TypingIndicator: View {
    let userName: String
    @State private var animating = false
    
    var body: some View {
        HStack {
            // Typing bubble (like iMessage)
            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .opacity(animating ? 1.0 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
            )
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    TypingIndicator(userName: "Alice")
}

