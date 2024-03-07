//
//  DomainProfileSuggestion.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

struct DomainProfileSuggestion: Hashable, Codable, Identifiable {
    var id: String { domain }
    
    let address: String
    let reasons: [String]
    let score: Int
    let domain: String
    let imageUrl: URL?
    let imageType: DomainProfileImageType?
    var isFollowing: Bool = false
    
    var classifiedReasons: [Reason] { reasons.compactMap { Reason(rawValue: $0) } }
    
    func getReasonToShow() -> Reason? {
        classifiedReasons.first
    }
    
    enum Reason: String {
        case nftCollection = "Holds the same NFT collection"
        case poap = "Holds the same POAP"
        case transaction = "Shared a transaction"
        case lensFollows = "Lens follows in common"
        case farcasterFollows = "Farcaster follows in common"
        
        var title: String {
            rawValue
        }
        
        var icon: Image {
            switch self {
            case .nftCollection:
                return .cryptoFaceIcon
            case .poap:
                return .cryptoPOAPIcon
            case .transaction:
                return .cryptoTransactionIcon
            case .lensFollows:
                return .lensIcon
            case .farcasterFollows:
                return .farcasterIcon
            }
        }
    }
}
