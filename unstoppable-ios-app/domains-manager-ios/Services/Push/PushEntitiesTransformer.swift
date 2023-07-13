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
        let metadataModel = PushEnvironment.UserProfileServiceMetadata(encryptedPrivateKey: pushUser.encryptedPrivateKey)
        let serviceMetadata = metadataModel.jsonData()
        let wallet = getWalletAddressFrom(eip155String: pushUser.wallets) ?? pushUser.wallets
        let userId = pushUser.did
        let displayInfo = MessagingChatUserProfileDisplayInfo(id: userId,
                                                              wallet: wallet,
                                                              name: pushUser.profile.name,
                                                              about: pushUser.profile.desc)
        let userProfile = MessagingChatUserProfile(id: userId,
                                                   wallet: wallet,
                                                   displayInfo: displayInfo,
                                                   serviceMetadata: serviceMetadata)
        return userProfile
    }
    
    static func convertPushChatToChat(_ pushChat: PushChat,
                                      userId: String,
                                      userWallet: String,
                                      isApproved: Bool,
                                      publicKeys: [String]) -> MessagingChat? {
        
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
            var adminWallet: String?
            if let admin = groupInfo.members.first(where: { $0.isAdmin }) {
                adminWallet = getWalletAddressFrom(eip155String: admin.wallet)
            }
            let pendingMembers = convertChatMembersToUserDisplayInfo(groupInfo.pendingMembers)
            let groupChatDetails = MessagingGroupChatDetails(members: members,
                                                             pendingMembers: pendingMembers,
                                                             name: groupInfo.groupName,
                                                             adminWallet: adminWallet)
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
        
        let metadataModel = PushEnvironment.ChatServiceMetadata(threadHash: pushChat.threadhash,
                                                                publicKeys: publicKeys)
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
              let id = pushMessage.cid,
              let chatServiceMetadata = chat.serviceMetadata,
              let chatMetadata = (try? JSONDecoder().decode(PushEnvironment.ChatServiceMetadata.self, from: chatServiceMetadata)),
              let (type, encryptedSecret) = extractPushMessageType(from: pushMessage, pgpKey: pgpKey, chatPublicKeys: chatMetadata.publicKeys) else { return nil }
        
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
                                                                   encryptedSecret: encryptedSecret,
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
    
    private static let pgpEncryptionType = "pgp"
    
    private static func extractPushMessageType(from pushMessage: Push.Message,
                                               pgpKey: String,
                                               chatPublicKeys: [String]) -> (MessagingChatMessageDisplayType, String)? {
        let messageType = PushMessageType(rawValue: pushMessage.messageType) ?? .unknown
        let isMessageEncrypted = pushMessage.encType == pgpEncryptionType
        let encryptedContent = pushMessage.messageContent
        guard let decryptedContent = try? Push.PushChat.decryptMessage(message: pushMessage, privateKeyArmored: pgpKey) else { return nil }
        
        let type: MessagingChatMessageDisplayType
        var encryptedSecret = pushMessage.encryptedSecret
        
        func encryptMessageContentIfNeeded(_ messageContent: String) -> String? {
            if isMessageEncrypted {
                guard !chatPublicKeys.isEmpty,
                      let (encryptedPureContent, newEncryptedSecret) = try? encryptText(messageContent, publicKeys: chatPublicKeys) else { return nil }
                
                encryptedSecret = newEncryptedSecret
                return encryptedPureContent
            }
            return messageContent
        }

        switch messageType {
        case .text:
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: decryptedContent,
                                                                          encryptedText: encryptedContent)
            type = .text(textDisplayInfo)
        case .image:
            guard let contentInfo = PushEnvironment.PushMessageContentResponse.objectFromJSONString(decryptedContent) else { return nil }
            let base64Image = contentInfo.content
            guard let encryptedImage = encryptMessageContentIfNeeded(base64Image) else { return nil }
            
            let imageBase64DisplayInfo = MessagingChatMessageImageBase64TypeDisplayInfo(base64: base64Image,
                                                                                        encryptedContent: encryptedImage)
            type = .imageBase64(imageBase64DisplayInfo)
        default:
            guard let contentInfo = PushEnvironment.PushMessageContentResponse.objectFromJSONString(decryptedContent) else { return nil }
            guard let messageContent = encryptMessageContentIfNeeded(contentInfo.content) else { return nil }
            
            let unknownDisplayInfo = MessagingChatMessageUnknownTypeDisplayInfo(encryptedContent: messageContent,
                                                                                type: pushMessage.messageType,
                                                                                name: contentInfo.name,
                                                                                size: contentInfo.size)
            type = .unknown(unknownDisplayInfo)
        }
        
        return (type, encryptedSecret)
    }
    
    static func convertPushMessageToWebSocketMessageEntity(_ pushMessage: Push.Message,
                                                           pgpKey: String) -> MessagingWebSocketMessageEntity? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let receiverWallet = getWalletAddressFrom(eip155String: pushMessage.toDID),
              let id = pushMessage.cid else { return nil }
        
        let serviceContent = PushEnvironment.PushSocketMessageServiceContent(pushMessage: pushMessage, pgpKey: pgpKey)
        return MessagingWebSocketMessageEntity(id: id,
                                               senderWallet: senderWallet,
                                               receiverWallet: receiverWallet,
                                               serviceContent: serviceContent,
                                               transformToMessageBlock: convertMessagingWebSocketMessageEntityToChatMessage)
    }
    
    static func convertGroupPushMessageToWebSocketGroupMessageEntity(_ pushMessage: Push.Message) -> MessagingWebSocketGroupMessageEntity? {
        let serviceContent = PushEnvironment.PushSocketGroupMessageServiceContent(pushMessage: pushMessage)
        return MessagingWebSocketGroupMessageEntity(chatId: pushMessage.toDID,
                                                    serviceContent: serviceContent,
                                                    transformToMessageBlock: convertMessagingWebSocketGroupMessageEntityToChatMessage)
    }
    
    static func convertMessagingWebSocketMessageEntityToChatMessage(_ webSocketMessage: MessagingWebSocketMessageEntity,
                                                                    in chat: MessagingChat) -> MessagingChatMessage? {
        guard let serviceContent = webSocketMessage.serviceContent as? PushEnvironment.PushSocketMessageServiceContent else { return nil }
        
        let pushMessage = serviceContent.pushMessage
        let pgpKey = serviceContent.pgpKey
        
        return convertPushMessageToChatMessage(pushMessage, in: chat, pgpKey: pgpKey, isRead: false)
    }
    
    static func convertMessagingWebSocketGroupMessageEntityToChatMessage(_ webSocketMessage: MessagingWebSocketGroupMessageEntity,
                                                                         in chat: MessagingChat) -> MessagingChatMessage? {
        let thisUserWallet = chat.displayInfo.thisUserDetails.wallet
        guard let pgpKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: thisUserWallet),
              let serviceContent = webSocketMessage.serviceContent as? PushEnvironment.PushSocketGroupMessageServiceContent else { return nil }
        
        let pushMessage = serviceContent.pushMessage
        
        return convertPushMessageToChatMessage(pushMessage, in: chat, pgpKey: pgpKey, isRead: false)
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
    
    static func convertPushInboxToChannelFeed(_ pushNotification: PushInboxNotification,
                                              isRead: Bool) -> MessagingNewsChannelFeed {
        let data = pushNotification.payload.data
        var link: URL?
        if let url = URL(string: data.url ?? "") {
            link = url
        } else if let acta = URL(string: data.acta ?? "") {
            link = acta
        }
        return MessagingNewsChannelFeed(id: String(pushNotification.payloadId),
                                        title: data.asub,
                                        message: data.amsg,
                                        link: link,
                                        time: PushISODateFormatter.date(from: pushNotification.epoch) ?? Date(),
                                        isRead: isRead,
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
    
    private static func encryptText(_ text: String, publicKeys: [String]) throws -> (encryptedText: String, encryptedSecret: String) {
        let aesKey = getRandomHexString(length: 15)
        let cipherText = try AESCBCHelper.encrypt(messageText: text, secretKey: aesKey)
        let encryptedAES = try Pgp.pgpEncryptV2(message: aesKey, pgpPublicKeys: publicKeys)
        
        return (cipherText, encryptedAES)
    }
    
}
