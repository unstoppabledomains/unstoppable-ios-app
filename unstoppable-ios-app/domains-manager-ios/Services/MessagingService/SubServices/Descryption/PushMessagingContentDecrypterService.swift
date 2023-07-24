//
//  PushMessagingContentDecrypterService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.06.2023.
//

import Foundation
import Push

final class PushMessagingContentDecrypterService: MessagingContentDecrypterService {
    
    private var pgpKeysCache = [String : String]()
    
    func isMessageEncrypted(serviceMetadata: Data?) -> Bool {
        guard let serviceMetadata,
              let messageMetadata = (try? JSONDecoder().decode(PushEnvironment.MessageServiceMetadata.self, from: serviceMetadata)) else { return false }
        
        return isMessageDataEncrypted(messageMetadata: messageMetadata)
    }
    
    func decryptText(_ text: String, with serviceMetadata: Data?, wallet: String) throws -> String {
        guard let serviceMetadata,
              let pgpKey = getPGPKeyFor(wallet: wallet),
              let messageMetadata = (try? JSONDecoder().decode(PushEnvironment.MessageServiceMetadata.self, from: serviceMetadata)) else {
            throw EncryptionError.failedToGatherRequiredData
        }
        
        if isMessageDataEncrypted(messageMetadata: messageMetadata) {
            return try Push.PushChat.decryptMessage(text,
                                                    encryptedSecret: messageMetadata.encryptedSecret,
                                                    privateKeyArmored: pgpKey)
        }
        return text
    }
    
    private func isMessageDataEncrypted(messageMetadata: PushEnvironment.MessageServiceMetadata) -> Bool {
        switch EncryptionType(rawValue: messageMetadata.encType) {
        case .none:
            return false
        case .pgp:
            return true
        }
    }
    
    private func getPGPKeyFor(wallet: String) -> String? {
        if let cachedKey = pgpKeysCache[wallet] {
            return cachedKey
        }
        
        if let pgpKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet) {
            pgpKeysCache[wallet] = pgpKey
            return pgpKey
        }
        
        return nil
    }
     
    private enum EncryptionType: String {
        case pgp
    }
}

// MARK: - Open methods
extension PushMessagingContentDecrypterService {
    enum EncryptionError: String, LocalizedError {
        case failedToGatherRequiredData
        
        public var errorDescription: String? { rawValue }

    }
}
