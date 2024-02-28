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
                                                              serviceIdentifier: .push,
                                                              name: pushUser.profile.name,
                                                              about: pushUser.profile.desc,
                                                              unreadMessagesCount: nil)
        let userProfile = MessagingChatUserProfile(id: userId,
                                                   wallet: wallet,
                                                   displayInfo: displayInfo,
                                                   serviceMetadata: serviceMetadata)
        return userProfile
    }
    
    struct CommunityChatDetails {
        let badgeInfo: BadgeDetailedInfo
        let blockedUsersList: [String]
    }
    
    static func convertPushChatToChat(_ pushChat: PushChat,
                                      userId: String,
                                      userWallet: String,
                                      isApproved: Bool,
                                      communityChatDetails: CommunityChatDetails? = nil) -> MessagingChat? {
        
        func convertChatMembersToUserDisplayInfo(_ members: [PushGroupChatMember]) -> [MessagingChatUserDisplayInfo] {
            members.compactMap({
                if $0.wallet == userWallet {
                    return nil // Exclude current user from other members list
                } else if let address = getWalletAddressFrom(eip155String: $0.wallet) {
                    return MessagingChatUserDisplayInfo(wallet: address,
                                                        pfpURL: URL(string: $0.image ?? ""))
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
            
            
            if let communityChatDetails {
                let blockedUsersList = prepare(blockedUsersList: communityChatDetails.blockedUsersList)
                let isJoined = members.first(where: { $0.wallet.lowercased() == userWallet.lowercased() }) != nil
                let communityChatDetails = MessagingCommunitiesChatDetails(type: .badge(communityChatDetails.badgeInfo),
                                                                           isJoined: isJoined,
                                                                           isPublic: groupInfo.isPublic,
                                                                           members: members,
                                                                           pendingMembers: pendingMembers,
                                                                           adminWallets: adminWallets,
                                                                           blockedUsersList: blockedUsersList)
                
                chatType = .community(communityChatDetails)
            } else {
                let groupChatDetails = MessagingGroupChatDetails(members: members,
                                                                 pendingMembers: pendingMembers,
                                                                 name: groupInfo.groupName,
                                                                 adminWallets: adminWallets,
                                                                 isPublic: groupInfo.isPublic)
                chatType = .group(groupChatDetails)
            }
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
                                                   serviceIdentifier: .push,
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
    
    static func buildEmptyCommunityChatFor(badgeInfo: BadgeDetailedInfo,
                                           user: MessagingChatUserProfile,
                                           blockedUsersList: [String]) -> MessagingChat {
        let thisUserDetails = MessagingChatUserDisplayInfo(wallet: user.wallet)
        let blockedUsersList = prepare(blockedUsersList: blockedUsersList)
        let info = MessagingChatDisplayInfo(id: "push_community_" + badgeInfo.badge.code,
                                            thisUserDetails: thisUserDetails,
                                            avatarURL: URL(string: badgeInfo.badge.logo),
                                            serviceIdentifier: .push,
                                            type: .community(.init(type: .badge(badgeInfo),
                                                                   isJoined: false,
                                                                   isPublic: true,
                                                                   members: [],
                                                                   pendingMembers: [],
                                                                   adminWallets: [], 
                                                                   blockedUsersList: blockedUsersList)),
                                            unreadMessagesCount: 0,
                                            isApproved: true,
                                            lastMessageTime: Date())
        let metadataModel = PushEnvironment.ChatServiceMetadata(threadHash: nil)
        let serviceMetadata = metadataModel.jsonData()
        return MessagingChat(userId: user.id,
                             displayInfo: info,
                             serviceMetadata: serviceMetadata)
    }
    
    private static func prepare(blockedUsersList: [String]) -> [String] {
        blockedUsersList.compactMap { getWalletAddressFrom(eip155String: $0)?.normalized }
    }
    
    static func getPushChatIdFrom(chat: MessagingChat) -> String {
        let id = chat.displayInfo.id
        return id.components(separatedBy: "_").first ?? id
    }
        
    static private func prepareSecretKeysFor(sessionKeys: Set<String>,
                                             pgpKey: String,
                                             env: Push.ENV) async {
        let sessionKeys = sessionKeys.filter { PushChatsSecretKeysStorage.instance.getSecretKeyFor(sessionKey: $0) == nil }
        guard !sessionKeys.isEmpty else { return }
        
        await withTaskGroup(of: Optional<PushEnvironment.SessionKeyWithSecret>.self) { group in
            for sessionKey in sessionKeys {
                group.addTask {
                    if let secretKey = try? await Push.PushChat.getPrivateGroupPGPSecretKey(sessionKey: sessionKey,
                                                                         privateKeyArmored: pgpKey,
                                                                                            env: env) {
                        return .init(sessionKey: sessionKey, secretKey: secretKey)
                    }
                    return nil
                }
            }
            
            for await result in group {
                if let result {
                    try? PushChatsSecretKeysStorage.instance.saveNew(keys: result)
                }
            }
        }
    }
    
    static func convertPushMessagesToChatMessage(_ pushMessages: [Push.Message],
                                                 in chat: MessagingChat,
                                                 pgpKey: String,
                                                 isRead: Bool,
                                                 filesService: MessagingFilesServiceProtocol,
                                                 env: Push.ENV) async -> [MessagingChatMessage] {
        let sessionKeys = pushMessages.compactMap { $0.sessionKey }
        await prepareSecretKeysFor(sessionKeys: Set(sessionKeys),
                                   pgpKey: pgpKey,
                                   env: env)
        
        var chatMessages: [MessagingChatMessage] = []
        for pushMessage in pushMessages {
            if let chatMessage = await convertPushMessageToChatMessage(pushMessage,
                                                                       in: chat,
                                                                       pgpKey: pgpKey,
                                                                       isRead: isRead,
                                                                       filesService: filesService,
                                                                       env: env) {
                chatMessages.append(chatMessage)
            }
        }
        
        return chatMessages
    }
    
    private static let pgpEncryptionTypes: Set<String> = ["pgp", "pgpv1:group"]
    
    static func convertPushMessageToChatMessage(_ pushMessage: Push.Message,
                                                in chat: MessagingChat,
                                                pgpKey: String,
                                                isRead: Bool,
                                                filesService: MessagingFilesServiceProtocol,
                                                env: Push.ENV) async -> MessagingChatMessage? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let id = pushMessage.cid,
              let type = try? await extractPushMessageType(from: pushMessage,
                                                           messageId: id,
                                                           userId: chat.userId,
                                                           pgpKey: pgpKey,
                                                           filesService: filesService,
                                                           env: env) else { return nil }
        
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
                                                                   link: pushMessage.link)
        let serviceMetadata = metadataModel.jsonData()
        let isMessageEncrypted = pgpEncryptionTypes.contains(pushMessage.encType)

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
        
    static func convertPushMessageToWebSocketMessageEntity(_ pushMessage: Push.Message,
                                                           pgpKey: String) -> MessagingWebSocketMessageEntity? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let receiverWallet = getWalletAddressFrom(eip155String: pushMessage.toDID),
              let id = pushMessage.cid else { return nil }
        
        let serviceContent = PushEnvironment.PushSocketMessageServiceContent(pushMessage: pushMessage, pgpKey: pgpKey)
        return MessagingWebSocketMessageEntity(id: id,
                                               senderWallet: senderWallet,
                                               receiverWallet: receiverWallet, 
                                               serviceIdentifier: .push,
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
                                                                    filesService: MessagingFilesServiceProtocol) async -> MessagingChatMessage? {
        guard let serviceContent = webSocketMessage.serviceContent as? PushEnvironment.PushSocketMessageServiceContent else { return nil }
        
        let pushMessage = serviceContent.pushMessage
        let pgpKey = serviceContent.pgpKey
        let thisUserWallet = chat.displayInfo.thisUserDetails.wallet
        let env = PushServiceHelper.getCurrentPushEnvironment()
        return await convertPushMessageToChatMessage(pushMessage,
                                                     in: chat,
                                                     pgpKey: pgpKey,
                                                     isRead: thisUserWallet == webSocketMessage.senderWallet,
                                                     filesService: filesService,
                                                     env: env)
    }
    
    static func convertMessagingWebSocketGroupMessageEntityToChatMessage(_ webSocketMessage: MessagingWebSocketGroupMessageEntity,
                                                                         in chat: MessagingChat,
                                                                         filesService: MessagingFilesServiceProtocol) async -> MessagingChatMessage? {
        let thisUserWallet = chat.displayInfo.thisUserDetails.wallet
        guard let pgpKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: thisUserWallet),
              let serviceContent = webSocketMessage.serviceContent as? PushEnvironment.PushSocketGroupMessageServiceContent,
              let fromWallet = getWalletAddressFrom(eip155String: serviceContent.pushMessage.fromDID) else { return nil }
        
        let pushMessage = serviceContent.pushMessage
        let env = PushServiceHelper.getCurrentPushEnvironment()

        return await convertPushMessageToChatMessage(pushMessage,
                                                     in: chat,
                                                     pgpKey: pgpKey,
                                                     isRead: fromWallet == thisUserWallet,
                                                     filesService: filesService,
                                                     env: env)
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
    
}

// MARK: - Message related methods
private extension PushEntitiesTransformer {
    static func extractPushMessageType(from pushMessage: Push.Message,
                                       messageId: String,
                                       userId: String,
                                       pgpKey: String,
                                       filesService: MessagingFilesServiceProtocol,
                                       env: Push.ENV) async throws -> MessagingChatMessageDisplayType? {
        let messageType = PushMessageType(rawValue: pushMessage.messageType) ?? .unknown
        
        guard let (decryptedContent, messageObj) = try? await decrypt(pushMessage: pushMessage,
                                                                      pgpKey: pgpKey,
                                                                      env: env) else {
            return nil
        }
        
        return try parseMessageFromPushMessage(decryptedContent: decryptedContent,
                                               messageObj: messageObj ?? pushMessage.messageObj,
                                               messageType: messageType,
                                               messageId: messageId,
                                               userId: userId,
                                               filesService: filesService)
    }
    
    static func parseMessageFromPushMessage(decryptedContent: String,
                                            messageObj: String?,
                                            messageType: PushMessageType,
                                            messageId: String,
                                            userId: String,
                                            filesService: MessagingFilesServiceProtocol) throws -> MessagingChatMessageDisplayType? {
        switch messageType {
        case .text:
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: decryptedContent)
            return .text(textDisplayInfo)
        case .image:
            guard let contentInfo = PushEnvironment.PushMessageContentResponse.objectFromJSONString(decryptedContent) else { return nil }
            let base64Image = contentInfo.content
            let imageBase64DisplayInfo = MessagingChatMessageImageBase64TypeDisplayInfo(base64: base64Image)
            return .imageBase64(imageBase64DisplayInfo)
        case .reaction:
            guard let messageObj,
                  let contentInfo = PushEnvironment.PushMessageReactionContent.objectFromJSONString(messageObj) else { 
                return nil }
            let messageId = parseReferenceIdToMessage(from: contentInfo.reference)
            return .reaction(.init(content: contentInfo.content, messageId: messageId))
        case .reply:
            guard let messageObj,
                  let contentInfo = PushEnvironment.PushMessageReplyContent.objectFromJSONString(messageObj),
                  let messageType = PushMessageType(rawValue: contentInfo.content.messageType) else { 
                return nil }
            guard let contentType = try parseMessageFromPushMessage(decryptedContent: contentInfo.content.messageObj.content,
                                                                    messageObj: nil,
                                                                    messageType: messageType,
                                                                    messageId: messageId,
                                                                    userId: userId,
                                                                    filesService: filesService) else { return nil }
            let messageId = parseReferenceIdToMessage(from: contentInfo.reference)

            return .reply(.init(contentType: contentType, messageId: messageId))
        case .meta:
            guard let messageObj,
                  let contentInfo = PushEnvironment.PushMessageMetaContent.objectFromJSONString(messageObj) else { return nil }
            
            return nil
        case .mediaEmbed:
            guard let messageObj,
                  let contentInfo = PushEnvironment.PushMessageMediaEmbeddedContent.objectFromJSONString(messageObj),
                  let serviceData = try? contentInfo.jsonDataThrowing() else { return nil }
            
            
            let displayInfo = MessagingChatMessageRemoteContentTypeDisplayInfo(serviceData: serviceData)
            return .remoteContent(displayInfo)
        default:
            guard let contentInfo = PushEnvironment.PushMessageContentResponse.objectFromJSONString(decryptedContent) else { return nil }
            guard let data = contentInfo.content.data(using: .utf8) else { return nil }
            
            let fileName = messageId + "_" + String(userId.suffix(4)) + "_" + (contentInfo.name ?? "")
            try filesService.saveData(data, fileName: fileName)
            let unknownDisplayInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: fileName,
                                                                                type: messageType.rawValue,
                                                                                name: contentInfo.name,
                                                                                size: contentInfo.size)
            return .unknown(unknownDisplayInfo)
        }
    }
    
    static func parseReferenceIdToMessage(from reference: String) -> String {
        reference.replacingOccurrences(of: "previous:", with: "") /// Push prefix
    }
    
    static func decrypt(pushMessage: Push.Message,
                                pgpKey: String,
                                env: Push.ENV) async throws -> (String, String?) {
        
        if let sessionKey = pushMessage.sessionKey,
           let secretKey = PushChatsSecretKeysStorage.instance.getSecretKeyFor(sessionKey: sessionKey) {
            return try Push.PushChat.decryptPrivateGroupMessage(pushMessage,
                                                                using: secretKey,
                                                                privateKeyArmored: pgpKey,
                                                                env: env)
        }
        
        return try await Push.PushChat.decryptMessage(message: pushMessage,
                                                      privateKeyArmored: pgpKey,
                                                      env: env)
    }
}
