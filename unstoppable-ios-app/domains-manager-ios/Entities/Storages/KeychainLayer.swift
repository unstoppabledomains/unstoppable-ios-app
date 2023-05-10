//
//  KeychainLayer.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 13.01.2021.
//

import Foundation
import Valet
import CryptoSwift
import CryptoKit

enum ValetError: String, LocalizedError {
    case failedToRead
    case failedToSave
    case failedToFind
    case failedToEncrypt
    case failedHashPassword
    case failedToDecrypt
    case noFreeSlots
    
    public var errorDescription: String? {
        return rawValue
    }
}

enum KeychainKey: String {
    case passcode = "SA_passcode_key"
    case analyticsId = "analytics_uuid"
}

protocol ValetProtocol {
    func setString(_ privateKey: String, forKey: String) throws
    func string(forKey pubKeyHex: String) throws -> String
    func removeObject(forKey: String) throws
}

extension Valet: ValetProtocol {}

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
    
    func retrieveValue(for key: KeychainKey, isCritical: Bool = true) -> String? {
        retrieveValue(for: key.rawValue, isCritical: isCritical)
    }
    
    func retrieveValue(for key: String, isCritical: Bool = true) -> String? {
        do {
            let value = try valet.string(forKey: key)
            Debugger.printInfo("Retrieved private key for key: \(key)")
            return value
        } catch {
            Debugger.printFailure("Failed to get the priv key for the key: \(key) with error \(error.localizedDescription)", critical: isCritical)
            return nil
        }
    }
    
    func retrievePrivateKey(for pubKeyHex: String, isCritical: Bool = true) -> String? {
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

struct KeychainPrivateKeyStorage: PrivateKeyStorage {
    let valet: ValetProtocol
    static let keychainName = "unstoppable-keychain"
    private init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    static var instance = KeychainPrivateKeyStorage()
    
    static func retrievePasscode() -> String? {
        Self.instance.retrieveValue(for: .passcode, isCritical: false)
    }
}

struct iCloudPrivateKeyStorage: PrivateKeyStorage {
    let valet: ValetProtocol
    static let iCloudName = "unstoppable-icloud-storage"
    init() {
        valet = Valet.iCloudValet(with: Identifier(nonEmpty: Self.iCloudName)!,
                                  accessibility: .whenUnlocked)
    }
}

enum Seed: CustomStringConvertible, Equatable {
    case encryptedPrivateKey (String)
    case encryptedSeedPhrase (String)
    
    var description: String {
        switch self {
        case .encryptedPrivateKey(let pk): return pk
        case .encryptedSeedPhrase(let phrase): return phrase
        }
    }
    
    static let seedWordsCount = 12
}
