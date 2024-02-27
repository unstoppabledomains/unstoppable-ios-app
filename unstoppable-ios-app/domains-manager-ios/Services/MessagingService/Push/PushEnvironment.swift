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
    }
    
    struct MessageServiceMetadata: Codable {
        let encType: String
        var link: String?
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
    
    struct PushMessageReactionContent: Codable {
        let content: String
        let reference: String
        
        enum CodingKeys: String, CodingKey {
            case content
            case reference = "refrence"
        }
    }
    
    struct PushMessageReplyContent: Codable {
        let content: ReplyContent
        let reference: String
        
        struct ReplyContent: Codable {
            let messageType: String
            let messageObj: ReplyObjectContent
        }
        
        struct ReplyObjectContent: Codable {
            let content: String
        }
    }
    
    struct PushMessageMetaContent: Codable {
        let content: String
        let info: [String : AnyCodable]
    }
    
    struct PushMessageMediaEmbeddedContent: Codable {
        let content: URL
    }
    
    struct SessionKeyWithSecret: Codable {
        let sessionKey: String
        let secretKey: String
    }
    
    struct PushSocketMessageServiceContent {
        let pushMessage: Push.Message
        let pgpKey: String
    }
    
    struct PushSocketGroupMessageServiceContent {
        let pushMessage: Push.Message
    }
}
