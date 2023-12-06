//
//  PurchasedDomainsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import Foundation

struct PurchasedDomainsStorage {
    
    @UserDefaultsCodableValue(key: .purchasedDomains) private static var purchasedDomains: [PendingPurchasedDomain]?
    @UserDefaultsCodableValue(key: .purchasedDomainsPendingProfiles) private static var purchasedDomainsPendingProfiles: [DomainProfilePendingChanges]?

    static func savePurchasedDomains(_ purchasedDomains: [PendingPurchasedDomain]) {
        PurchasedDomainsStorage.purchasedDomains = purchasedDomains
    }
    
    static func retrievePurchasedDomains() -> [PendingPurchasedDomain] {
        PurchasedDomainsStorage.purchasedDomains ?? []
    }
  
    static func savePendingNonEmptyProfiles(_ pendingProfiles: [DomainProfilePendingChanges]) {
        PurchasedDomainsStorage.purchasedDomainsPendingProfiles = pendingProfiles.filter { !$0.isEmpty }
    }
    
    static func retrievePendingProfiles() -> [DomainProfilePendingChanges] {
        PurchasedDomainsStorage.purchasedDomainsPendingProfiles ?? []
    }
    
}
