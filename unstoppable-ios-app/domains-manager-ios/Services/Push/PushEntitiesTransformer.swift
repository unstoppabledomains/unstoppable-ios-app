//
//  PushEntitiesTransformer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation
import Push

struct PushEntitiesTransformer {
    
    static let PushISODateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter
    }()
    
    
    static func convertPushUserToChatUser(_ pushUser: PushUser) -> MessagingChatUserProfile {
        let metadataModel = PushEnvironment.UserProfileServiceMetadata(encryptedPrivateKey: pushUser.encryptedPrivateKey,
                                                                       sigType: pushUser.sigType,
                                                                       signature: pushUser.signature)
        let serviceMetadata = metadataModel.jsonData()
        let wallet = getWalletAddressFrom(eip155String: pushUser.wallets) ?? pushUser.wallets
        let userId = pushUser.did
        let displayInfo = MessagingChatUserProfileDisplayInfo(id: userId,
                                                              wallet: wallet,
                                                              name: pushUser.name,
                                                              about: pushUser.about)
        let userProfile = MessagingChatUserProfile(id: userId,
                                                   wallet: wallet,
                                                   displayInfo: displayInfo,
                                                   serviceMetadata: serviceMetadata)
        return userProfile
    }
    
    static func convertPushChatToChat(_ pushChat: PushChat,
                                      userId: String,
                                      userWallet: String,
                                      isApproved: Bool) -> MessagingChat? {
        
        func convertChatMembersToUserDisplayInfo(_ members: [PushGroupChatMember]) -> [MessagingChatUserDisplayInfo] {
            members.compactMap({
                if $0.wallet == userWallet {
                    return nil // Exclude current user from other members list
                } else {
                    return getWalletAddressFrom(eip155String: $0.wallet)
                }
            }).map({ MessagingChatUserDisplayInfo(wallet: $0) })
        }
        
        let thisUserInfo = MessagingChatUserDisplayInfo(wallet: userWallet)
        let chatType: MessagingChatType
        if let groupInfo = pushChat.groupInformation {
            let members = convertChatMembersToUserDisplayInfo(groupInfo.members)
            let pendingMembers = convertChatMembersToUserDisplayInfo(groupInfo.pendingMembers)
            let groupChatDetails = MessagingGroupChatDetails(members: members,
                                                             pendingMembers: pendingMembers)
            chatType = .group(groupChatDetails)
        } else {
            let fromUserEip = pushChat.intentSentBy
            guard let fromUserWallet = getWalletAddressFrom(eip155String: fromUserEip),
                  let toUserEip = pushChat.did,
                  let toUserWallet = getWalletAddressFrom(eip155String: toUserEip) else { return nil }
            let otherUserWallet = userWallet.lowercased() == fromUserWallet.lowercased() ? toUserWallet : fromUserWallet
            let otherUserInfo = MessagingChatUserDisplayInfo(wallet: otherUserWallet)
            let privateChatDetails = MessagingPrivateChatDetails(otherUser: otherUserInfo)
            chatType = .private(privateChatDetails)
        }
        
        var avatarURL: URL?
        if let profilePicture = pushChat.profilePicture {
            avatarURL = URL(string: profilePicture)
        }
        
        var lastMessageTime = Date()
        if let date = PushISODateFormatter.date(from: pushChat.intentTimestamp) {
            lastMessageTime = date
        }
        
        let chatId = pushChat.chatId + "_" + userId // unique for users
        let displayInfo = MessagingChatDisplayInfo(id: chatId,
                                                   thisUserDetails: thisUserInfo,
                                                   avatarURL: avatarURL,
                                                   type: chatType,
                                                   unreadMessagesCount: 0,
                                                   isApproved: isApproved,
                                                   lastMessageTime: lastMessageTime,
                                                   lastMessage: nil)
        
        let metadataModel = PushEnvironment.ChatServiceMetadata(threadHash: pushChat.threadhash)
        let serviceMetadata = metadataModel.jsonData()
        let chat = MessagingChat(userId: userId,
                                 displayInfo: displayInfo,
                                 serviceMetadata: serviceMetadata)
        return chat
    }
    
    static func getPushChatIdFrom(chat: MessagingChat) -> String {
        let id = chat.displayInfo.id
        return id.components(separatedBy: "_").first ?? id
    }
    
    static func convertPushMessageToChatMessage(_ pushMessage: Push.Message,
                                                in chat: MessagingChat,
                                                pgpKey: String,
                                                isRead: Bool) -> MessagingChatMessage? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let messageType = PushMessageType(rawValue: pushMessage.messageType),
              let id = pushMessage.cid else { return nil }
        
        let encryptedContent = pushMessage.messageContent
        guard let decryptedContent = try? Push.PushChat.decryptMessage(message: pushMessage, privateKeyArmored: pgpKey) else { return nil }
        
        let type: MessagingChatMessageDisplayType
        
        switch messageType {
        case .text:
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: decryptedContent,
                                                                          encryptedText: encryptedContent)
            type = .text(textDisplayInfo)
        case .image:
            guard let contentInfo = PushEnvironment.PushImageContentResponse.objectFromJSONString(decryptedContent) else { return nil }
            let imageBase64DisplayInfo = MessagingChatMessageImageBase64TypeDisplayInfo(base64: contentInfo.content,
                                                                                        encryptedContent: encryptedContent)
            type = .imageBase64(imageBase64DisplayInfo)
        default:
            return nil
        }
        
        var time = Date()
        if let timestamp = pushMessage.timestamp {
            time = Date(millisecondsSince1970: timestamp)
        }
        
        let userDisplayInfo = MessagingChatUserDisplayInfo(wallet: senderWallet)
        let sender: MessagingChatSender
        if chat.displayInfo.thisUserDetails.wallet == senderWallet {
            sender = .thisUser(userDisplayInfo)
        } else {
            sender = .otherUser(userDisplayInfo)
        }
        let metadataModel = PushEnvironment.MessageServiceMetadata(encType: pushMessage.encType,
                                                                   encryptedSecret: pushMessage.encryptedSecret,
                                                                   link: pushMessage.link)
        let serviceMetadata = metadataModel.jsonData()
        
        let displayInfo = MessagingChatMessageDisplayInfo(id: id,
                                                          chatId: chat.displayInfo.id,
                                                          senderType: sender,
                                                          time: time,
                                                          type: type,
                                                          isRead: isRead,
                                                          isFirstInChat: false,
                                                          deliveryState: .delivered)
        let chatMessage = MessagingChatMessage(displayInfo: displayInfo,
                                               serviceMetadata: serviceMetadata)
        return chatMessage
    }
    
    static func convertPushMessageToWebSocketMessageEntity(_ pushMessage: Push.Message,
                                                           pgpKey: String) -> MessagingWebSocketMessageEntity? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let receiverWallet = getWalletAddressFrom(eip155String: pushMessage.toDID),
              let messageType = PushMessageType(rawValue: pushMessage.messageType),
              let id = pushMessage.cid else { return nil }
        
        
        switch messageType {
        case .text:
            let encryptedText = pushMessage.messageContent
            guard let text = try? Push.PushChat.decryptMessage(message: pushMessage, privateKeyArmored: pgpKey) else { return nil }
            
            var time = Date()
            if let timestamp = pushMessage.timestamp {
                time = Date(millisecondsSince1970: timestamp)
            }
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: text,
                                                                          encryptedText: encryptedText)
            let senderDisplayInfo = MessagingChatUserDisplayInfo(wallet: senderWallet)
            let metadataModel = PushEnvironment.MessageServiceMetadata(encType: pushMessage.encType,
                                                                       encryptedSecret: pushMessage.encryptedSecret,
                                                                       link: pushMessage.link)
            let serviceMetadata = metadataModel.jsonData()
            let messageEntity = MessagingWebSocketMessageEntity(id: id,
                                                                senderDisplayInfo: senderDisplayInfo,
                                                                senderWallet: senderWallet,
                                                                receiverWallet: receiverWallet,
                                                                time: time,
                                                                type: .text(textDisplayInfo),
                                                                serviceMetadata: serviceMetadata,
                                                                transformToMessageBlock: convertMessagingWebSocketMessageEntityToChatMessage)
            return messageEntity
        default:
            return nil // Not supported for now
        }
    }
    
    static func convertMessagingWebSocketMessageEntityToChatMessage(_ webSocketMessage: MessagingWebSocketMessageEntity,
                                                                    in chat: MessagingChat) -> MessagingChatMessage {
        let messageDisplayInfo = MessagingChatMessageDisplayInfo(id: webSocketMessage.id,
                                                                 chatId: chat.displayInfo.id,
                                                                 senderType: .otherUser(webSocketMessage.senderDisplayInfo),
                                                                 time: webSocketMessage.time,
                                                                 type: webSocketMessage.type,
                                                                 isRead: false,
                                                                 isFirstInChat: false,
                                                                 deliveryState: .delivered)
        
        let message = MessagingChatMessage(displayInfo: messageDisplayInfo,
                                           serviceMetadata: webSocketMessage.serviceMetadata)
        return message
    }
    
    static func convertPushChannelToMessagingChannel(_ pushChannel: PushChannel,
                                                     isCurrentUserSubscribed: Bool,
                                                     userId: String) -> MessagingNewsChannel {
        MessagingNewsChannel(id: String(pushChannel.id),
                             userId: userId,
                             channel: pushChannel.channel,
                             name: pushChannel.name,
                             info: pushChannel.info,
                             url: pushChannel.url,
                             icon: pushChannel.icon,
                             verifiedStatus: pushChannel.verified_status,
                             blocked: pushChannel.blocked,
                             subscriberCount: pushChannel.subscriber_count,
                             unreadMessagesCount: 0,
                             isUpToDate: true,
                             isCurrentUserSubscribed: isCurrentUserSubscribed)
    }
    
    static func convertPushInboxToChannelFeed(_ pushNotification: PushInboxNotification) -> MessagingNewsChannelFeed {
        MessagingNewsChannelFeed(id: String(pushNotification.payloadId),
                                 title: pushNotification.payload.data.asub,
                                 message: pushNotification.payload.data.amsg,
                                 link: pushNotification.payload.data.url,
                                 time: PushISODateFormatter.date(from: pushNotification.epoch) ?? Date(),
                                 isRead: false,
                                 isFirstInChannel: false)
    }
    
    static func getWalletAddressFrom(eip155String: String) -> String? {
        let components = eip155String.components(separatedBy: ":")
        if components.count == 2 {
            return components[1]
        } else if components.count == 1,
                  eip155String.isValidAddress() {
            return components[0]
        }
        return nil
    }
    
  
}
