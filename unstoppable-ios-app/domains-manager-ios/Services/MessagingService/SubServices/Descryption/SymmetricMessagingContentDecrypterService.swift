//
//  SymmetricMessagingContentDecrypterService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.07.2023.
//

import Foundation
import CryptoKit
import Valet

final class SymmetricMessagingContentDecrypterService: MessagingContentDecrypterService {
    
    private let storage = KeychainSymmetricPasswordStorage.instance
    private var cachedKey: SymmetricKey?

    func encryptText(_ text: String) throws -> String {
        let key256 = try getOrCreateAESPassword()
        guard let data = text.data(using: .utf8) else { throw EncryptionError.failedToGetDataRepresentationOfString }
        guard let sealedBoxData = try AES.GCM.seal(data, using: key256).combined else { throw EncryptionError.failedToCreateSealedBox }
        let encryptedString = sealedBoxData.base64EncodedString()
        
        return encryptedString
    }
    
    func decryptText(_ text: String) throws -> String {
        let key256 = try getOrCreateAESPassword()
        guard let sealedBoxData = Data(base64Encoded: text) else { throw EncryptionError.failedToGetDataRepresentationOfString }
        let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key256)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else { throw EncryptionError.failedToGetStringRepresentationOfData }

        return decryptedString
    }
    
}

// MARK: - Private methods
private extension SymmetricMessagingContentDecrypterService {
    func getOrCreateAESPassword() throws -> SymmetricKey {
        if let cachedKey {
            return cachedKey
        }
        
        if let storedKeyData = storage.getKeyData() {
            let storedKey = SymmetricKey(data: storedKeyData)
            cachedKey = storedKey
            return storedKey
        }
        
        let newKey = SymmetricKey(size: .bits256)
        let newKeyData = newKey.withUnsafeBytes { Data(Array($0)) }
        try storage.saveKeyData(newKeyData)
        cachedKey = newKey
        
        return newKey
    }
    
    enum EncryptionError: String, LocalizedError {
        case failedToGetDataRepresentationOfString
        case failedToGetStringRepresentationOfData
        case failedToCreateSealedBox
    }
}

// MARK: - Secure Storage
private extension SymmetricMessagingContentDecrypterService {
    struct KeychainSymmetricPasswordStorage: PrivateKeyStorage {
        let valet: ValetProtocol
        
        static let keychainName = "unstoppable-keychain-symmetric-key"
        private let keychainKey = "com.unstoppable.symmetric.key"
        
        private init() {
            valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                                accessibility: .whenUnlockedThisDeviceOnly)
        }
        
        static var instance = KeychainSymmetricPasswordStorage()
        
        func saveKeyData(_ password: Data) throws {
            store(data: password, for: keychainKey)
        }
        
        func getKeyData() -> Data? {
            retrieveData(for: keychainKey, isCritical: false)
        }
        
        func clearKeyData()  {
            clear(forKey: keychainKey)
        }
    }
}
