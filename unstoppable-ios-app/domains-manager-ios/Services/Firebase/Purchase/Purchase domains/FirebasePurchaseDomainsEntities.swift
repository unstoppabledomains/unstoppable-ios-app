//
//  FirebasePurchaseEntities.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

// MARK: - Search entities
extension FirebasePurchaseDomainsService {
    struct SearchDomainsResponse: Codable {
        @DecodeHashableIgnoringFailed
        var exact: [FirebasePurchase.DomainProductItem]
        let searchQuery: String
        let invalidCharacters: [String]
        let invalidReason: String?
    }
    
    struct SuggestDomainsResponse: Codable {
        @DecodeHashableIgnoringFailed
        var suggestions: [FirebasePurchase.DomainProductItem]
    }
}

