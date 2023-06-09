//
//  PushMessagingContentDecrypterService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.06.2023.
//

import Foundation
import Push

final class PushMessagingContentDecrypterService: MessagingContentDecrypterService {
    func decryptText(_ text: String, with serviceMetadata: Data?, wallet: String) throws -> String {
        guard let serviceMetadata,
              let pgpKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet),
              let messageMetadata = (try? JSONDecoder().decode(PushEnvironment.MessageServiceMetadata.self, from: serviceMetadata)) else {
            throw NSError()
        }
        
        if messageMetadata.encType != "pgp" {
            return text
        }
        
        return text // TODO: - Use function from the SDK to decrypt the message
    }
}
