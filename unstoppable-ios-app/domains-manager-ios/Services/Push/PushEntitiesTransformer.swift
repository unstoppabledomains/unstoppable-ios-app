//
//  PushEntitiesTransformer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation
import Push

struct PushEntitiesTransformer {
    static func convertPushUserToChatUser(_ pushUser: PushUser) -> MessagingChatUserDisplayInfo {
        MessagingChatUserDisplayInfo(wallet: pushUser.wallets,
                                     domainName: nil,
                                     pfpURL: nil)
    }
    
    static func convertPushChatToChat(_ pushChat: PushChat,
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
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        var lastMessageTime = Date()
        if let date = formatter.date(from: pushChat.intentTimestamp)  {
            lastMessageTime = date
        }
        
        let displayInfo = MessagingChatDisplayInfo(id: pushChat.chatId,
                                                   thisUserDetails: thisUserInfo,
                                                   avatarURL: avatarURL,
                                                   type: chatType,
                                                   unreadMessagesCount: 0,
                                                   isApproved: isApproved,
                                                   lastMessageTime: lastMessageTime,
                                                   lastMessage: nil)
        
        let metadataModel = PushEnvironment.ChatServiceMetadata(threadHash: pushChat.threadhash)
        let serviceMetadata = metadataModel.jsonData()
        let chat = MessagingChat(displayInfo: displayInfo,
                                 serviceMetadata: serviceMetadata)
        return chat
    }
    
    static func convertPushMessageToChatMessage(_ pushMessage: Push.Message,
                                                in chat: MessagingChat,
                                                pgpKey: String) -> MessagingChatMessage? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let messageType = PushMessageType(rawValue: pushMessage.messageType) else { return nil }
        
        switch messageType {
        case .text:
            let encryptedText = pushMessage.messageContent
            guard let text = try? Push.PushChat.decryptMessage(message: pushMessage, privateKeyArmored: pgpKey) else { return nil }
          
            var time = Date()
            var id = "\(pushMessage.fromDID)_\(pushMessage.messageContent)"
            
            if let timestamp = pushMessage.timestamp {
                time = Date(millisecondsSince1970: timestamp)
                id += "_\(timestamp)"
            }
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: text,
                                                                          encryptedText: encryptedText)
            let userDisplayInfo = MessagingChatUserDisplayInfo(wallet: senderWallet)
            let sender: MessagingChatSender
            if chat.displayInfo.thisUserDetails.wallet == senderWallet {
                sender = .thisUser(userDisplayInfo)
            } else {
                sender = .otherUser(userDisplayInfo)
            }
            let metadataModel = PushEnvironment.MessageServiceMetadata(encType: pushMessage.encType,
                                                                       encryptedSecret: pushMessage.encryptedSecret)
            let serviceMetadata = metadataModel.jsonData()
            
            let displayInfo = MessagingChatMessageDisplayInfo(id: id,
                                                              chatId: chat.displayInfo.id,
                                                              senderType: sender,
                                                              time: time,
                                                              type: .text(textDisplayInfo),
                                                              isRead: false,
                                                              deliveryState: .delivered)
            let textMessage = MessagingChatMessage(displayInfo: displayInfo,
                                                   serviceMetadata: serviceMetadata)
            return textMessage
        default:
            return nil // Not supported for now
        }
    }
    
    func decryptMessage(_ message: Push.Message,
                        fromWallet wallet: String) -> String {
       if let pgpKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet),
            let decryptedMessage = try? Push.PushChat.decryptMessage(message: message, privateKeyArmored: pgpKey) {
                return decryptedMessage
        }
        return message.messageContent
    }
    
    static func convertPushMessageToWebSocketMessageEntity(_ pushMessage: Push.Message,
                                                           pgpKey: String) -> MessagingWebSocketMessageEntity? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let receiverWallet = getWalletAddressFrom(eip155String: pushMessage.toDID),
              let messageType = PushMessageType(rawValue: pushMessage.messageType) else { return nil }
        
        
        switch messageType {
        case .text:
            let encryptedText = pushMessage.messageContent
            guard let text = try? Push.PushChat.decryptMessage(message: pushMessage, privateKeyArmored: pgpKey) else { return nil }
            
            var time = Date()
            var id = "\(pushMessage.fromDID)_\(pushMessage.messageContent)"
            
            if let timestamp = pushMessage.timestamp {
                time = Date(millisecondsSince1970: timestamp)
                id += "_\(timestamp)"
            }
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: text,
                                                                          encryptedText: encryptedText)
            let senderDisplayInfo = MessagingChatUserDisplayInfo(wallet: senderWallet)
            let metadataModel = PushEnvironment.MessageServiceMetadata(encType: pushMessage.encType,
                                                                       encryptedSecret: pushMessage.encryptedSecret)
            let serviceMetadata = metadataModel.jsonData()
            let messageEntity = MessagingWebSocketMessageEntity(id: id,
                                                                senderDisplayInfo: senderDisplayInfo,
                                                                senderWallet: senderWallet,
                                                                receiverWallet: receiverWallet,
                                                                time: time,
                                                                type: .text(textDisplayInfo),
                                                                serviceMetadata: serviceMetadata)
            return messageEntity
        default:
            return nil // Not supported for now
        }
    }
    
    static func convertPushChannelToMessagingChannel(_ pushChannel: PushChannel) -> MessagingNewsChannel {
        MessagingNewsChannel(id: String(pushChannel.id),
                             name: pushChannel.name,
                             info: pushChannel.info,
                             url: pushChannel.url,
                             icon: pushChannel.icon,
                             verifiedStatus: pushChannel.verified_status,
                             blocked: pushChannel.blocked,
                             subscriberCount: pushChannel.subscriber_count,
                             unreadMessagesCount: 0)
    }
    
    static func convertPushInboxToChannelFeed(_ pushNotification: PushInboxNotification) -> MessagingNewsChannelFeed {
        MessagingNewsChannelFeed(id: String(pushNotification.payloadId),
                                 title: pushNotification.payload.data.asub,
                                 message: pushNotification.payload.data.amsg,
                                 link: pushNotification.payload.data.url,
                                 time: pushNotification.epoch,
                                 isRead: false)
    }
    
    static func getWalletAddressFrom(eip155String: String) -> String? {
        let components = eip155String.components(separatedBy: ":")
        if components.count == 2 {
            return components[1]
        }
        return nil
    }
}
