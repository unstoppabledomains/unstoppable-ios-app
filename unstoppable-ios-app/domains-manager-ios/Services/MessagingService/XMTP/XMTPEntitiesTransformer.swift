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
    
    
    static func convertXMTPChatToChat(_ xmtpChat: XMTP.Conversation,
                                      userId: String,
                                      userWallet: String,
                                      isApproved: Bool) -> MessagingChat? {
        
        let thisUserInfo = MessagingChatUserDisplayInfo(wallet: userWallet)
        let chatType: MessagingChatType
        
        // MARK: - Group chats not supported at the moment 
//        if xmtpChat.isGroup {
//            let groupChatDetails = MessagingGroupChatDetails(members: [],
//                                                             pendingMembers: [],
//                                                             name: "",
//                                                             adminWallets: [userWallet],
//                                                             isPublic: false)
//            chatType = .group(groupChatDetails)
//        } else {
            let otherUserWallet = xmtpChat.peerAddress
            let otherUserInfo = MessagingChatUserDisplayInfo(wallet: otherUserWallet)
            let privateChatDetails = MessagingPrivateChatDetails(otherUser: otherUserInfo)
            chatType = .private(privateChatDetails)
//        }
        
        var avatarURL: URL?
        var lastMessageTime = Date() // TODO: - Make optional?
        let chatId = xmtpChat.topic
        let displayInfo = MessagingChatDisplayInfo(id: chatId,
                                                   thisUserDetails: thisUserInfo,
                                                   avatarURL: avatarURL,
                                                   type: chatType,
                                                   unreadMessagesCount: 0,
                                                   isApproved: isApproved,
                                                   lastMessageTime: lastMessageTime,
                                                   lastMessage: nil)
        
        let metadataModel = XMTPEnvironmentNamespace.ChatServiceMetadata(encodedContainer: xmtpChat.encodedContainer)
        let serviceMetadata = metadataModel.jsonData()
        let chat = MessagingChat(userId: userId,
                                 displayInfo: displayInfo,
                                 serviceMetadata: serviceMetadata)
        return chat
    }
    
    
}
