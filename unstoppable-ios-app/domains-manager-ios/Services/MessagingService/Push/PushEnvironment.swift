//
//  PushEnvironment.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation
import Push

enum PushEnvironment {
    static var baseURL: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "https://backend-staging.epns.io"
        } else {
            return "https://backend.epns.io"
        }
    }
    
    struct ChatServiceMetadata: Codable {
        let threadHash: String?
        let publicKeys: [String]
    }
    
    struct MessageServiceMetadata: Codable {
        let encType: String
        let link: String?
    }
    
    struct UserProfileServiceMetadata: Codable {
        let encryptedPrivateKey: String
    }
    
    struct PushMessageContentResponse: Codable {
        let content: String
        var name: String?
        var type: String?
        var size: Int?
    }
    
    struct ChatPublicKeysHolder: Codable {
        let chatId: String
        let publicKeys: [String]
    }
    
    struct PushSocketMessageServiceContent {
        let pushMessage: Push.Message
        let pgpKey: String
    }
    
    struct PushSocketGroupMessageServiceContent {
        let pushMessage: Push.Message
    }
}
