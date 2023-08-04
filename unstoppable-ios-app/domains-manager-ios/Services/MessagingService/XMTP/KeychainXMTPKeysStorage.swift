//
//  KeychainXMTPKeysStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import Valet
import XMTP

protocol KeychainXMTPKeysStorageProtocol {
    func saveKeysData(_ keysData: Data,
                      forIdentifier identifier: String,
                      env: XMTPEnvironment)
    func getKeysDataFor(identifier: String,
                        env: XMTPEnvironment) -> Data?
    func clearKeysDataFor(identifier: String,
                          env: XMTPEnvironment)
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
    
    func saveKeysData(_ keysData: Data,
                      forIdentifier identifier: String,
                      env: XMTPEnvironment) {
        let key = getKeyFor(identifier: identifier,
                            env: env)
        store(data: keysData, for: key)
    }
    
    func getKeysDataFor(identifier: String,
                        env: XMTPEnvironment) -> Data? {
        let key = getKeyFor(identifier: identifier,
                            env: env)
        return retrieveData(for: key, isCritical: false)
    }
 
    func clearKeysDataFor(identifier: String,
                          env: XMTPEnvironment)  {
        let key = getKeyFor(identifier: identifier,
                            env: env)
        clear(forKey: key)
    }
    
    private func getKeyFor(identifier: String,
                           env: XMTPEnvironment) -> String {
        xmtpPrefix + identifier + "_" + environmentIdentifier(env: env)
    }
    
    private func environmentIdentifier(env: XMTPEnvironment) -> String {
        env == .dev ? "testnet" : "mainnet"
    }
    
}

