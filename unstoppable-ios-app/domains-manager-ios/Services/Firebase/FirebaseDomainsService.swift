//
//  FirebaseDomainsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.03.2023.
//

import Foundation

protocol FirebaseDomainsServiceProtocol {
    func getCachedDomains() -> [FirebaseDomain]
    func loadParkedDomains() async throws -> [FirebaseDomain]
}

final class FirebaseDomainsService {
    
    private let firebaseInteractionService: FirebaseDomainsLoaderProtocol
    private let storage = FirebaseDomainsStorage.instance
    
    init(firebaseInteractionService: FirebaseDomainsLoaderProtocol) {
        self.firebaseInteractionService = firebaseInteractionService
    }
    
}

extension FirebaseDomainsService: FirebaseDomainsServiceProtocol {
    func getCachedDomains() -> [FirebaseDomain] {
        storage.getFirebaseDomains()
    }
    
    func loadParkedDomains() async throws -> [FirebaseDomain] {
        let domains = try await firebaseInteractionService.getParkedDomains()
        
        storage.saveFirebaseDomains(domains)
        
        return domains
    }
}
