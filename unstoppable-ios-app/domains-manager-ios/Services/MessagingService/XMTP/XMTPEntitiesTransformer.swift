//
//  XMTPEntitiesTransformer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import XMTP

struct XMTPEntitiesTransformer {
    
    static func convertXMTPClientToChatUser(_ client: XMTP.Client) -> MessagingChatUserProfile {
        let wallet = client.address
        let userId = client.address
        let displayInfo = MessagingChatUserProfileDisplayInfo(id: userId,
                                                              wallet: wallet,
                                                              name: nil,
                                                              about: nil,
                                                              unreadMessagesCount: nil)
        let userProfile = MessagingChatUserProfile(id: userId,
                                                   wallet: wallet,
                                                   displayInfo: displayInfo,
                                                   serviceMetadata: nil)
        return userProfile
        
    }
    
}
