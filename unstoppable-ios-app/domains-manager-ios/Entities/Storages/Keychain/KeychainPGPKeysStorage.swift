//
//  KeychainPGPKeysStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation
import Valet

protocol KeychainPGPKeysStorageProtocol {
    func savePGPKey(_ pgpKey: String, forIdentifier identifier: String)
    func getPGPKeyFor(identifier: String) -> String?
}

struct KeychainPGPKeysStorage: PrivateKeyStorage, KeychainPGPKeysStorageProtocol {
    let valet: ValetProtocol
    
    static let keychainName = "unstoppable-keychain-pgp-keys"
    private let pgpPrefix = "pgp_"
    
    private init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    static var instance: KeychainPGPKeysStorageProtocol = KeychainPGPKeysStorage()
    
    func savePGPKey(_ pgpKey: String, forIdentifier identifier: String) {
        let key = getKeyFor(identifier: identifier)
        store(value: pgpKey, for: key)
    }
    
    func getPGPKeyFor(identifier: String) -> String? {
        let key = getKeyFor(identifier: identifier)
        return retrieveValue(for: key, isCritical: false)
    }
    
    private func getKeyFor(identifier: String) -> String {
        pgpPrefix + identifier
    }
}
