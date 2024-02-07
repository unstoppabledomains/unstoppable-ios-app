//
//  Date.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.01.2023.
//

import Foundation

extension Date {
    init(millisecondsSince1970: Int) {
        self.init(timeIntervalSince1970: TimeInterval(millisecondsSince1970 / 1000))
    }
}

extension Date {
    static var format: String { "HH:mm E, d MMM y" }
    
    var string: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.format
        return formatter.string(from: self)
    }
    
    init(string: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.format
        self = formatter.date(from: string) ?? Date()
    }
    
    static var formatUTC: String { "HH:mm E, d MMM y" }
    
    var stringUTC: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.formatUTC
        return formatter.string(from: self)
    }
    
    init(stringUTC: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.formatUTC
        self = formatter.date(from: stringUTC) ?? Date()
    }
    
    static let isoCalendar = Calendar.current

    var dayStart: Date {
        Date.isoCalendar.startOfDay(for: self)
    }
    
    var isToday: Bool {
        Date.isoCalendar.isDateInToday(self)
    }
    
    var yesterday: Date {
        Date.isoCalendar.date(byAdding: .day, value: -1, to: self)!
    }
    
    var weekNumber: Int {
        Date.isoCalendar.component(.weekOfYear, from: self)
    }
    
    var yearNumber: Int {
        Date.isoCalendar.component(.year, from: self)
    }
    
    var isCurrentWeek: Bool {
        self.weekNumber == Date().weekNumber && isCurrentYear
    }
    
    var isCurrentYear: Bool {
        self.yearNumber == Date().yearNumber
    }
    
    func dateDifferenceBetween(date: Date) -> DateComponents {
        Date.isoCalendar.dateComponents([.day, .month, .year], from: (date > self ? self : date).dayStart, to: (date < self ? self : date).dayStart)
    }
    
    func adding(days: Int) -> Date {
        Date.isoCalendar.date(byAdding: .day, value: days, to: self) ?? Date()
    }
}
