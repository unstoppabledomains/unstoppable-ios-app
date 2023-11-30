//
//  PurchasedDomainsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import Foundation

struct PurchasedDomainsStorage {
    private enum Key: String {
        case purchasedDomainsKey = "PURCHASED_DOMAINS_ARRAY_KEY"
    }
    
    enum Error: Swift.Error {
        case failedToEncode
        case failedToDecode
    }
    
    static func save(purchasedDomains: [PendingPurchasedDomain]) {
        guard let data = purchasedDomains.jsonData() else {
            Debugger.printFailure("Failed to encode purchased domains", critical: true)
            return
        }
        save(data: data, key: .purchasedDomainsKey)
    }
    
    static private func save(data: Data, key: Key) {
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
    
    static func retrievePurchasedDomains() -> [PendingPurchasedDomain] {
        guard let data = retrieve(key: .purchasedDomainsKey) else { return [] }
        guard let object: [PendingPurchasedDomain] = [PendingPurchasedDomain].genericObjectFromData(data) else {
            Debugger.printFailure("Failed to decode purchased domains", critical: true)
            return []
        }
        return object
    }
    
    static private func retrieve(key: Key) -> Data? {
        UserDefaults.standard.object(forKey: key.rawValue) as? Data
    }
    
    static func clearPurchasedDomains() {
        clean(key: .purchasedDomainsKey)
    }
    
    static private func clean(key: Key)  {
        UserDefaults.standard.set(nil, forKey: key.rawValue)
    }
}
