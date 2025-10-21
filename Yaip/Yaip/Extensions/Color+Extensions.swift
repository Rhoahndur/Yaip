//
//  Color+Extensions.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

extension Color {
    /// App brand colors
    static let primaryBlue = Color.blue
    static let secondaryGray = Color.gray.opacity(0.2)
    
    /// Message bubble colors
    static let sentMessageBackground = Color.blue
    static let receivedMessageBackground = Color.gray.opacity(0.2)
    static let sentMessageText = Color.white
    static let receivedMessageText = Color.primary
    
    /// AI feature colors
    static let aiPurple = Color.purple
    static let aiPurpleLight = Color.purple.opacity(0.1)
    
    /// Status colors
    static let statusOnline = Color.green
    static let statusAway = Color.orange
    static let statusOffline = Color.gray
}

