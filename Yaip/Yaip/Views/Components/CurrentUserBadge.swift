//
//  CurrentUserBadge.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

/// Shows the currently signed-in user
struct CurrentUserBadge: View {
    let displayName: String
    let email: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.blue)
            
            Text(displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.blue)
            
            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

#Preview {
    CurrentUserBadge(displayName: "Alice Smith", email: "alice@test.com")
}

