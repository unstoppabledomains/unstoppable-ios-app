//
//  RecentDomainsToPurchaseSearchStorageProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2024.
//

import Foundation

protocol RecentDomainsToPurchaseSearchStorageProtocol {
    func getRecentDomainsToPurchaseSearches() -> [String]
    func addDomainToPurchaseSearchToRecents(_ search: String)
    func removeDomainToPurchaseSearchToRecents(_ search: String)
    func clearRecentDomainsToPurchaseSearches()
}
