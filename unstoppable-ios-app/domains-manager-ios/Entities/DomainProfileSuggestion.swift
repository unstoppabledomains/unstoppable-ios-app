//
//  DomainProfileSuggestion.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

struct DomainProfileSuggestion: Hashable, Identifiable {
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
        case nftCollection = "NftCollection"
        case poap = "POAP"
        case transaction = "Tx"
        case lensFollows = "Lens"
        case lensMutual = "LensMutual"
        case farcasterFollows = "Farcaster"
        case farcasterMutual = "FarcasterMutual"
        
        var title: String {
            switch self {
            case .nftCollection:
                return String.Constants.profileSuggestionReasonNFTCollection.localized()
            case .poap:
                return String.Constants.profileSuggestionReasonPOAP.localized()
            case .transaction:
                return String.Constants.profileSuggestionReasonTransaction.localized()
            case .lensFollows:
                return String.Constants.profileSuggestionReasonLensFollows.localized()
            case .lensMutual:
                return String.Constants.profileSuggestionReasonLensMutual.localized()
            case .farcasterFollows:
                return String.Constants.profileSuggestionReasonFarcasterFollows.localized()
            case .farcasterMutual:
                return String.Constants.profileSuggestionReasonFarcasterMutual.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .nftCollection:
                return .cryptoFaceIcon
            case .poap:
                return .cryptoPOAPIcon
            case .transaction:
                return .cryptoTransactionIcon
            case .lensFollows, .lensMutual:
                return .lensIcon
            case .farcasterFollows, .farcasterMutual:
                return .farcasterIcon
            }
        }
    }
}

extension DomainProfileSuggestion {
    init(serializedProfile: SerializedDomainProfileSuggestion) {
        self.address = serializedProfile.address
        self.reasons = serializedProfile.reasons.map { $0.id }
        self.score = serializedProfile.score
        self.domain = serializedProfile.domain
        self.imageUrl = URL(string: serializedProfile.imageUrl ?? "")
        self.imageType = serializedProfile.imageType
    }
}
