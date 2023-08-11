//
//  PushServiceHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import Push

struct PushServiceHelper {
    static func getCurrentPushEnvironment() -> Push.ENV {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .STAGING : .PROD
    }
    
    static func getPGPPrivateKeyFor(user: MessagingChatUserProfile) async throws -> String {
        let wallet = user.wallet
        if let key = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet) {
            return key
        }
        
        let userMetadata: PushEnvironment.UserProfileServiceMetadata = try MessagingAPIServiceHelper.decodeServiceMetadata(from: user.serviceMetadata)
        let domain = try await MessagingAPIServiceHelper.getAnyDomainItem(for: wallet)
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: userMetadata.encryptedPrivateKey, signer: domain)
        KeychainPGPKeysStorage.instance.savePGPKey(pgpPrivateKey, forIdentifier: wallet)
        return pgpPrivateKey
    }
}
