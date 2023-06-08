//
//  KeychainPGPKeysStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation
import Valet

struct KeychainPGPKeysStorage: PrivateKeyStorage {
    let valet: ValetProtocol
    
    static let keychainName = "unstoppable-keychain-pgp-keys"
    private static let pgpPrefix = "pgp_"
    
    private init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    static var instance = KeychainPGPKeysStorage()
    
    static func savePGPKey(_ pgpKey: String, forIdentifier identifier: String) {
        let key = getKeyFor(identifier: identifier)
        Self.instance.store(value: pgpKey, for: key)
    }
    
    static func getPGPKeyFor(identifier: String) -> String? {
        let key = getKeyFor(identifier: identifier)
        return Self.instance.retrieveValue(for: key, isCritical: false)
    }
    
    private static func getKeyFor(identifier: String) -> String {
        pgpPrefix + identifier
    }
}
