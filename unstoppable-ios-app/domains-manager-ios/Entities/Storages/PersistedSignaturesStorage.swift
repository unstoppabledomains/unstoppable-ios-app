//
//  PersistedSignaturesStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 24.11.2022.
//

import Foundation
struct PersistedTimedSignature: Codable {
    enum Kind: String, Codable {
        case viewUserProfile
    }
    
    let domainName: String
    let expires: UInt64
    let sign: String
    let kind: Kind
    
    var isExpired: Bool {
        return expires < Int( (Date().timeIntervalSince1970) * 1000)
    }
}

protocol PersistedSignaturesStorageProtocol {
    func getUserDomainProfileSignature(for domainName: String) throws -> PersistedTimedSignature
    func hasValidSignature(for domainName: String) -> Bool
    func saveNewSignature(sign: PersistedTimedSignature) throws
    func removeExpired()
    func revokeSignatures(for: DomainItem)
}

class PersistedSignaturesStorage: SecurePersistedStorage<PersistedTimedSignature> {
    func getAllSignatures() -> [PersistedTimedSignature] {
        getElements()
    }
    
    func removeExpired() {
        let onlyValid = getAllSignatures().filter({!$0.isExpired})
        clear()
        try? appendToStorage(elements: onlyValid)
    }
    
    func revokeSignatures(for domain: DomainItem) {
        let onlyOfOtherDomains = getAllSignatures().filter({$0.domainName != domain.name})
        clear()
        try? appendToStorage(elements: onlyOfOtherDomains)
    }
}

extension PersistedSignaturesStorage: PersistedSignaturesStorageProtocol {
    enum Error: String, Swift.Error {
        case notFound = "Signature not found"
        case foundOnlyExpired = "Found  only expired"
        case failedToSave = "Failed to save"
    }
    
    func getUserDomainProfileSignature(for domainName: String) throws -> PersistedTimedSignature {
        let domainSigs = getAllSignatures().filter({$0.domainName == domainName})
        guard !domainSigs.isEmpty else { throw Error.notFound }
        
        let validSigns = domainSigs.filter({!$0.isExpired})
        
        guard let found = validSigns.first else { throw Error.foundOnlyExpired }
        return found
    }
    
    func hasValidSignature(for domainName: String) -> Bool {
        (try? getUserDomainProfileSignature(for: domainName)) != nil
    }
    
    func saveNewSignature(sign: PersistedTimedSignature) throws {
        try save(element: sign)
    }
}

final class MockPersistedSignaturesStorage: PersistedSignaturesStorageProtocol {
    func getUserDomainProfileSignature(for domainName: String) throws -> PersistedTimedSignature {
        throw PersistedSignaturesStorage.Error.notFound
    }
    
    func hasValidSignature(for domainName: String) -> Bool {
        false
    }
    
    func saveNewSignature(sign: PersistedTimedSignature) throws {
        throw PersistedSignaturesStorage.Error.notFound
    }

    func removeExpired() { }
    
    func revokeSignatures(for: DomainItem) { }
}
