//
//  XMTPMessagingContentDecrypterService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2023.
//

import Foundation

final class XMTPMessagingContentDecrypterService: MessagingContentDecrypterService {
    
    private var xmtpKeysCache = [String : Data]()
    private let xmtpHelper = XMTPServiceHelper()

    func isMessageEncrypted(serviceMetadata: Data?) -> Bool {
        true
    }
    
    func decryptText(_ text: String, with serviceMetadata: Data?, wallet: String) throws -> String {
//        guard let serviceMetadata,
//              let keysData = getXMTPKeysDataFor(wallet: wallet),
//              let messageMetadata = (try? JSONDecoder().decode(PushEnvironment.MessageServiceMetadata.self, from: serviceMetadata)) else {
//            throw EncryptionError.failedToGatherRequiredData
//        }
        
        
        
//        if isMessageDataEncrypted(messageMetadata: messageMetadata) {
//            return try Push.PushChat.decryptMessage(text,
//                                                    encryptedSecret: messageMetadata.encryptedSecret,
//                                                    privateKeyArmored: pgpKey)
//        }
        return text
    }
    
    private func getXMTPKeysDataFor(wallet: String) -> Data? {
        if let cachedKey = xmtpKeysCache[wallet] {
            return cachedKey
        }
        
        let env = xmtpHelper.getCurrentXMTPEnvironment()
        if let keysData = KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) {
            xmtpKeysCache[wallet] = keysData
            return keysData
        }
        
        return nil
    }
}

// MARK: - Open methods
extension XMTPMessagingContentDecrypterService {
    enum EncryptionError: String, LocalizedError {
        case failedToGatherRequiredData
        
        public var errorDescription: String? { rawValue }
        
    }
}
