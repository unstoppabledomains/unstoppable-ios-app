//
//  KeychainXMTPKeysStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import Valet

protocol KeychainXMTPKeysStorageProtocol {
    func saveKeysData(_ keysData: Data, forIdentifier identifier: String)
    func getKeysDataFor(identifier: String) -> Data?
    func clearKeysDataFor(identifier: String)
}

struct KeychainXMTPKeysStorage: PrivateKeyStorage, KeychainXMTPKeysStorageProtocol {
    let valet: ValetProtocol
    
    static let keychainName = "unstoppable-keychain-xmtp-keys"
    private let xmtpPrefix = "xmtp_"
    
    private init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    static var instance: KeychainXMTPKeysStorageProtocol = KeychainXMTPKeysStorage()
    
    func saveKeysData(_ keysData: Data, forIdentifier identifier: String) {
        let key = getKeyFor(identifier: identifier)
        store(data: keysData, for: key)
    }
    
    func getKeysDataFor(identifier: String) -> Data? {
        let key = getKeyFor(identifier: identifier)
        return retrieveData(for: key, isCritical: false)
    }
 
    func clearKeysDataFor(identifier: String)  {
        let key = getKeyFor(identifier: identifier)
        clear(forKey: key)
    }
    
    private func getKeyFor(identifier: String) -> String {
        xmtpPrefix + identifier + "_" + environmentIdentifier()
    }
    
    private func environmentIdentifier() -> String {
        User.instance.getSettings().isTestnetUsed ? "testnet" : "mainnet"
    }
    
}

