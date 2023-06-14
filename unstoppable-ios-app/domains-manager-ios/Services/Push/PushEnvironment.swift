//
//  PushEnvironment.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

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
        let encryptedSecret: String
        let link: String?
    }
}
