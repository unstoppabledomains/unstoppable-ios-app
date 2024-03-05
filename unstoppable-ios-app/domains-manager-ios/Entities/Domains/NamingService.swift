//
//  NamingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

enum NamingService: String, Codable, CaseIterable {
    case UNS
    
    static let cases = NamingService.allCases
}
