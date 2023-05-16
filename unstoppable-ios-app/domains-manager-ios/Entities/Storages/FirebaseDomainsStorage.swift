//
//  FirebaseDomainsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.03.2023.
//

import Foundation

final class FirebaseDomainsStorage {
    
    static let storageFileName = "firebase-domains.data"

    static let instance = FirebaseDomainsStorage()
    
    private init() {}
    private var storage = SpecificStorage<[FirebaseDomain]>(fileName: FirebaseDomainsStorage.storageFileName)
    
    func getFirebaseDomains() -> [FirebaseDomain] {
        storage.retrieve() ?? []
    }
    
    func saveFirebaseDomains(_ firebaseDomains: [FirebaseDomain]) {
        set(newCachedDomains: firebaseDomains)
    }
    
    private func set(newCachedDomains: [FirebaseDomain]) {
        storage.store(newCachedDomains)
    }
}
