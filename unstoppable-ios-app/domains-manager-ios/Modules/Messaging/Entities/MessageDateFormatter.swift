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
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMdd")
        return formatter
    }()
 
    static func formatMessageDate(_ date: Date) -> String {
        todayFormatter.string(from: date)
    }
    
    static func formatChannelDate(_ date: Date) -> String {
        if date.isToday {
            return todayFormatter.string(from: date)
        } else if date.daysDifferenceBetween(date: Date()) <= 6 {
            return weekdayFormatter.string(from: date)
        } else if date.isCurrentYear {
            var formatted = shortDateFormatter.string(from: date)
            
            for char in formatted.reversed() {
                formatted.removeLast()
                if Int(String(char)) == nil {
                    break
                }
            }
            
            return formatted
        }
        
        return shortDateFormatter.string(from: date)
    }
    
    static func formatMessagesSectionDate(_ date: Date) -> String {
        if date.isToday {
            return String.Constants.today.localized()
        } else if date.yesterday.dayStart == date.dayStart {
            return String.Constants.yesterday.localized()
        } else if date.isCurrentYear {
            return mediumDateFormatter.string(from: date)
        }
        
        return shortDateFormatter.string(from: date)
    }
    
}
