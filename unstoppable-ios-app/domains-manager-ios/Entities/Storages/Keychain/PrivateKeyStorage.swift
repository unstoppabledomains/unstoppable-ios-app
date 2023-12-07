//
//  PrivateKeyStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

protocol PrivateKeyStorage {
    var valet: ValetProtocol { get }
}

extension PrivateKeyStorage {
    func store(_ value: String, for key: KeychainKey) {
        store(value: value, for: key.rawValue)
    }
    
    func store(value: String, for key: String) {
        do {
            try valet.setString(value, forKey: key)
            Debugger.printInfo("Stored value to iCloud keychain: \(key)")
        } catch {
            Debugger.printFailure("Failed to store value to iCloud keychain: \(key) with error \(error.localizedDescription)", critical: true)
        }
    }
    
    func store(privateKey: String, for pubKeyHex: String) {
        do {
            try valet.setString(privateKey, forKey: pubKeyHex.normalized)
            Debugger.printInfo("Stored private key for wallet: \(pubKeyHex)")
        } catch {
            Debugger.printFailure("Failed to store the priv key for the wallet: \(pubKeyHex) with error \(error.localizedDescription)", critical: true)
            return
        }
    }
    
    func retrieveValue(for key: KeychainKey, isCritical: Bool = false) -> String? {
        retrieveValue(for: key.rawValue, isCritical: isCritical)
    }
    
    func retrieveValue(for key: String, isCritical: Bool = false) -> String? {
        do {
            let value = try valet.string(forKey: key)
            Debugger.printInfo("Retrieved private key for key: \(key)")
            return value
        } catch {
            Debugger.printFailure("Failed to get the priv key for the key: \(key) with error \(error.localizedDescription)", critical: isCritical)
            return nil
        }
    }
    
    func retrievePrivateKey(for pubKeyHex: String, isCritical: Bool = false) -> String? {
        if let valueFromNormalizedKey = try? valet.string(forKey: pubKeyHex.normalized) {
            Debugger.printInfo("Retrieved private key for key: \(pubKeyHex.normalized)")
            return valueFromNormalizedKey
        }
        
        // try non normalized address for legacy keychain records
        do {
            let value = try valet.string(forKey: pubKeyHex)
            Debugger.printInfo("Retrieved private key for key: \(pubKeyHex) (non-normalized)")
            return value
        } catch {
            Debugger.printFailure("Failed to get the priv key for the key: \(pubKeyHex) with error \(error.localizedDescription)", critical: isCritical)
            return nil
        }
    }
    
    func clear(for key: KeychainKey) {
        clear(forKey: key.rawValue)
    }
    
    func clear(forKey key: String) {
        do {
            try valet.removeObject(forKey: key)
            Debugger.printInfo("Cleared private key for wallet: \(key)")
            return
        } catch {
            Debugger.printInfo("Failed to clear the priv key for the wallet: \(key) with error \(error.localizedDescription)")
            return
        }
    }
    
    func clear(for pubKeyHex: String) {
        try? valet.removeObject(forKey: pubKeyHex)
        try? valet.removeObject(forKey: pubKeyHex.normalized)
    }
}
extension PrivateKeyStorage {
    func store(data: Data, for key: String) {
        do {
            try valet.setObject(data, forKey: key)
            Debugger.printInfo("Stored data to keychain: \(key)")
        } catch {
            Debugger.printFailure("Failed to store data to keychain: \(key) with error \(error.localizedDescription)", critical: true)
        }
    }
    
    func retrieveData(for key: String, isCritical: Bool = false) -> Data? {
        do {
            let value = try valet.object(forKey: key)
            Debugger.printInfo("Retrieved keychain data for key: \(key)")
            return value
        } catch {
            Debugger.printFailure("Failed to get keychain data for the key: \(key) with error \(error.localizedDescription)", critical: isCritical)
            return nil
        }
    }
}
