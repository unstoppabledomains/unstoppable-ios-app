//
//  XMTPEnvironmentNamespace.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import XMTP

enum XMTPEnvironmentNamespace {
    
    struct ChatServiceMetadata: Codable {
        let encodedContainer: ConversationContainer
    }
    
}
