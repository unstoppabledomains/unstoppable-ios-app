//
//  AESMessagingContentDecrypterService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2023.
//

import Foundation
import Valet

final class AESMessagingContentDecrypterService: MessagingContentDecrypterService {
    
    private var cachedPassword: String?
    private let storage = KeychainAESPasswordStorage.instance
    
    func encryptText(_ text: String) throws -> String {
        let aesPassword = try getOrCreateAESPassword()
        return try Encrypting.encrypt(message: text, with: aesPassword)
    }

    func decryptText(_ text: String) throws -> String {
        let aesPassword = try getOrCreateAESPassword()
        return try Encrypting.decrypt(encryptedMessage: text, password: aesPassword)
    }
}

// MARK: - Private methods
private extension AESMessagingContentDecrypterService {
    func getOrCreateAESPassword() throws -> String {
        if let cachedPassword {
            return cachedPassword
        }
        
        if let storedPassword = storage.getPassword() {
            cachedPassword = storedPassword
            return storedPassword
        }
        
        let newPassword = UUID().uuidString
        try storage.savePassword(newPassword)
        cachedPassword = newPassword
        
        return newPassword
    }
}

// MARK: - Secure Storage
private extension AESMessagingContentDecrypterService {
    struct KeychainAESPasswordStorage: PrivateKeyStorage {
        let valet: ValetProtocol
        
        static let keychainName = "unstoppable-keychain-aes-password"
        private let passwordKey = "com.unstoppable.aes.password.key"
        
        private init() {
            valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                                accessibility: .whenUnlockedThisDeviceOnly)
        }
        
        static var instance = KeychainAESPasswordStorage()
        
        func savePassword(_ password: String) throws {
            try valet.setString(password, forKey: passwordKey)
        }
        
        func getPassword() -> String? {
            retrieveValue(for: passwordKey, isCritical: false)
        }
        
        func clearPassword()  {
            clear(forKey: passwordKey)
        }
    }
}
