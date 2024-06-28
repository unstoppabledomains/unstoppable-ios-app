//
//  BlockchainType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

enum BlockchainType: String, CaseIterable, Codable, Hashable {
    case Ethereum = "ETH"
    case Matic = "MATIC"
    
    static let cases = Self.allCases
    static let supportedCases: [BlockchainType] = [.Ethereum, .Matic]
    
    enum InitError: Error {
        case invalidBlockchainAbbreviation
    }
}
