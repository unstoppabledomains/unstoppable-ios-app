//
//  Date.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.01.2023.
//

import Foundation

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
}
