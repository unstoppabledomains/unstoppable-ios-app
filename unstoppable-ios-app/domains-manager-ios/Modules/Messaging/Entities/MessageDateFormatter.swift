//
//  MessageDateFormatter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

struct MessageDateFormatter {
    
    static let calendar = Date.isoCalendar
   
    static let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter
    }()
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    
    static func formatDate(_ date: Date) -> String {
        if date.isToday {
            return todayFormatter.string(from: date)
        } else if (date.dateDifferenceBetween(date: Date()).day ?? 0) <= 6 {
            return weekdayFormatter.string(from: date)
        } else if date.isCurrentYear {
            let formatted = shortDateFormatter.string(from: date)
            var components = formatted.components(separatedBy: ".")
            components.removeLast()
            return components.joined(separator: ".")
        }
        
        return shortDateFormatter.string(from: date)
    }
    
}
