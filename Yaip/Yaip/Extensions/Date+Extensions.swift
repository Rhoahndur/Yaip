//
//  Date+Extensions.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation

extension Date {
    /// Returns a relative time string like "2m", "1h", "Yesterday", "Mon", "Jan 15"
    var relativeTime: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day >= 7 {
            // More than a week ago - show date
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        } else if let day = components.day, day >= 2 {
            // 2-6 days ago - show day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: self)
        } else if let day = components.day, day >= 1 {
            // Yesterday
            return "Yesterday"
        } else if let hour = components.hour, hour >= 1 {
            // Hours ago
            return "\(hour)h"
        } else if let minute = components.minute, minute >= 1 {
            // Minutes ago
            return "\(minute)m"
        } else {
            // Just now
            return "now"
        }
    }
    
    /// Returns a formatted timestamp like "3:45 PM"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Returns a full date string like "Oct 20, 2025"
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

