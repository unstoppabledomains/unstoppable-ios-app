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
                                                              serviceIdentifier: Constants.pushMessagingServiceIdentifier,
                                                              name: pushUser.profile.name,
                                                              about: pushUser.profile.desc,
                                                              unreadMessagesCount: nil)
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
                } else if let address = getWalletAddressFrom(eip155String: $0.wallet) {
                    return MessagingChatUserDisplayInfo(wallet: address,
                                                        pfpURL: URL(string: $0.image))
                }
                return nil
            })
        }
        
        let thisUserInfo = MessagingChatUserDisplayInfo(wallet: userWallet)
        let chatType: MessagingChatType
        if let groupInfo = pushChat.groupInformation {
            let members = convertChatMembersToUserDisplayInfo(groupInfo.members)
            let allGroupMembers = groupInfo.members + groupInfo.pendingMembers
            let adminWallets = allGroupMembers.filter({ $0.isAdmin }).compactMap { getWalletAddressFrom(eip155String:  $0.wallet) }
        
            let pendingMembers = convertChatMembersToUserDisplayInfo(groupInfo.pendingMembers)
            let groupChatDetails = MessagingGroupChatDetails(members: members,
                                                             pendingMembers: pendingMembers,
                                                             name: groupInfo.groupName,
                                                             adminWallets: adminWallets,
                                                             isPublic: groupInfo.isPublic)
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
        
        let chatId = pushChat.chatId
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
                                                isRead: Bool,
                                                filesService: MessagingFilesServiceProtocol) -> MessagingChatMessage? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let id = pushMessage.cid,
              let chatServiceMetadata = chat.serviceMetadata,
              let chatMetadata = (try? JSONDecoder().decode(PushEnvironment.ChatServiceMetadata.self, from: chatServiceMetadata)),
              let (type, encryptedSecret) = try? extractPushMessageType(from: pushMessage,
                                                                        messageId: id,
                                                                        userId: chat.userId,
                                                                        pgpKey: pgpKey,
                                                                        chatPublicKeys: chatMetadata.publicKeys,
                                                                        filesService: filesService) else { return nil }
        
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
        let isMessageEncrypted = pushMessage.encType == pgpEncryptionType

        let displayInfo = MessagingChatMessageDisplayInfo(id: id,
                                                          chatId: chat.displayInfo.id,
                                                          userId: chat.userId,
                                                          senderType: sender,
                                                          time: time,
                                                          type: type,
                                                          isRead: isRead,
                                                          isFirstInChat: pushMessage.link == nil,
                                                          deliveryState: .delivered,
                                                          isEncrypted: isMessageEncrypted)
        let chatMessage = MessagingChatMessage(displayInfo: displayInfo,
                                               serviceMetadata: serviceMetadata)
        return chatMessage
    }
    
    private static let pgpEncryptionType = "pgp"
    
    private static func extractPushMessageType(from pushMessage: Push.Message,
                                               messageId: String,
                                               userId: String,
                                               pgpKey: String,
                                               chatPublicKeys: [String],
                                               filesService: MessagingFilesServiceProtocol) throws -> (MessagingChatMessageDisplayType, String)? {
        let messageType = PushMessageType(rawValue: pushMessage.messageType) ?? .unknown
        let isMessageEncrypted = pushMessage.encType == pgpEncryptionType
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
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: decryptedContent)
            type = .text(textDisplayInfo)
        case .image:
            guard let contentInfo = PushEnvironment.PushMessageContentResponse.objectFromJSONString(decryptedContent) else { return nil }
            let base64Image = contentInfo.content
            let imageBase64DisplayInfo = MessagingChatMessageImageBase64TypeDisplayInfo(base64: base64Image)
            type = .imageBase64(imageBase64DisplayInfo)
        default:
            guard let contentInfo = PushEnvironment.PushMessageContentResponse.objectFromJSONString(decryptedContent) else { return nil }
            guard let data = contentInfo.content.data(using: .utf8) else { return nil }
            
            let fileName = messageId + "_" + String(userId.suffix(4)) + "_" + (contentInfo.name ?? "")
            try filesService.saveData(data, fileName: fileName)
            let unknownDisplayInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: fileName,
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
                                                                    in chat: MessagingChat,
                                                                    filesService: MessagingFilesServiceProtocol) -> MessagingChatMessage? {
        guard let serviceContent = webSocketMessage.serviceContent as? PushEnvironment.PushSocketMessageServiceContent else { return nil }
        
        let pushMessage = serviceContent.pushMessage
        let pgpKey = serviceContent.pgpKey
        let thisUserWallet = chat.displayInfo.thisUserDetails.wallet

        return convertPushMessageToChatMessage(pushMessage,
                                               in: chat,
                                               pgpKey: pgpKey,
                                               isRead: thisUserWallet == webSocketMessage.senderWallet,
                                               filesService: filesService)
    }
    
    static func convertMessagingWebSocketGroupMessageEntityToChatMessage(_ webSocketMessage: MessagingWebSocketGroupMessageEntity,
                                                                         in chat: MessagingChat,
                                                                         filesService: MessagingFilesServiceProtocol) -> MessagingChatMessage? {
        let thisUserWallet = chat.displayInfo.thisUserDetails.wallet
        guard let pgpKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: thisUserWallet),
              let serviceContent = webSocketMessage.serviceContent as? PushEnvironment.PushSocketGroupMessageServiceContent,
              let fromWallet = getWalletAddressFrom(eip155String: serviceContent.pushMessage.fromDID) else { return nil }
        
        let pushMessage = serviceContent.pushMessage
        
        return convertPushMessageToChatMessage(pushMessage,
                                               in: chat,
                                               pgpKey: pgpKey,
                                               isRead: fromWallet == thisUserWallet,
                                               filesService: filesService)
    }
    
    static func convertPushChannelToMessagingChannel(_ pushChannel: PushChannel,
                                                     isCurrentUserSubscribed: Bool,
                                                     isSearchResult: Bool,
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
                             isCurrentUserSubscribed: isCurrentUserSubscribed,
                             isSearchResult: isSearchResult)
    }
    
    static func convertPushInboxToChannelFeed(_ pushNotification: PushInboxNotification,
                                              isRead: Bool) -> MessagingNewsChannelFeed {
        let data = pushNotification.payload.data
        var link: URL?
        if let ctaLink = URL(string: data.acta ?? "") {
            link = ctaLink
        } else if let mediaLink = URL(string: data.aimg ?? "") {
            link = mediaLink
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
