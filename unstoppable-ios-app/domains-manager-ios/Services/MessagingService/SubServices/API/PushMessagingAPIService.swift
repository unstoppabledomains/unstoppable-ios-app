//
//  PushMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import Push

final class PushMessagingAPIService {
    
    private let pushRESTService = PushRESTAPIService()
        
}

// MARK: - MessagingAPIServiceProtocol
extension PushMessagingAPIService: MessagingAPIServiceProtocol {
    // User profile
    func getUserFor(domain: DomainItem) async throws -> MessagingChatUserProfile {
        let wallet = try await domain.getAddress()
        let env = getCurrentPushEnvironment()
        
        guard let pushUser = try await PushUser.get(account: wallet, env: env) else {
            throw PushMessagingAPIServiceError.failedToGetPushUser
        }
        
        let userProfile = PushEntitiesTransformer.convertPushUserToChatUser(pushUser)
        try await storePGPKeyFromPushUserIfNeeded(pushUser, domain: domain)
        return userProfile
    }
    
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserProfile {
        let env = getCurrentPushEnvironment()
        let pushUser = try await PushUser.create(options: .init(env: env,
                                                                signer: domain,
                                                                version: .PGP_V3,
                                                                progressHook: nil))
        try await storePGPKeyFromPushUserIfNeeded(pushUser, domain: domain)
        let chatUser = PushEntitiesTransformer.convertPushUserToChatUser(pushUser)
        
        return chatUser
    }
    
    // Chats
    func getChatsListForUser(_ user: MessagingChatUserProfile,
                               page: Int,
                               limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await getPushChatsForUser(user,
                                                      page: page,
                                                      limit: limit,
                                                      isRequests: false)
        
        let chats = pushChats.compactMap({ PushEntitiesTransformer.convertPushChatToChat($0,
                                                                                         userId: user.id,
                                                                                         userWallet: user.wallet,
                                                                                         isApproved: true) })
        return chats
    }
    
    private func getPushChatsForUser(_ user: MessagingChatUserProfile,
                                     page: Int,
                                     limit: Int,
                                     isRequests: Bool) async throws -> [PushChat] {
        let wallet = user.wallet
        return try await pushRESTService.getChats(for: wallet,
                                                  page: page,
                                                  limit: limit,
                                                  isRequests: isRequests)
    }
    
    func getChatRequestsForUser(_ user: MessagingChatUserProfile,
                                  page: Int,
                                  limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await getPushChatsForUser(user,
                                                      page: page,
                                                      limit: limit,
                                                      isRequests: true)
        let chats = pushChats.compactMap({ PushEntitiesTransformer.convertPushChatToChat($0,
                                                                                         userId: user.id,
                                                                                         userWallet: user.wallet,
                                                                                         isApproved: false) })
        return chats
    }
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            options: MessagingAPIServiceLoadMessagesOptions,
                            fetchLimit: Int,
                            for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage] {
        switch options {
        case .default:
            let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
            guard let threadHash = chatMetadata.threadHash else {
                return [] // NULL threadHash means there's no messages in the chat yet
            }
            return try await getPreviousMessagesForChat(chat,
                                                        threadHash: threadHash,
                                                        fetchLimit: fetchLimit,
                                                        isRead: false,
                                                        for: user)
        case .before(let message):
            let messageMetadata: PushEnvironment.MessageServiceMetadata = try decodeServiceMetadata(from: message.serviceMetadata)
            guard let threadHash = messageMetadata.link else {
                return []
            }
            return try await getPreviousMessagesForChat(chat,
                                                        threadHash: threadHash,
                                                        fetchLimit: fetchLimit,
                                                        isRead: true,
                                                        for: user)
        case .after(let message):
            let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
            guard var threadHash = chatMetadata.threadHash else {
                return []
            }
            
            var messages = [MessagingChatMessage]()
            
            while true {
                let chunkMessages = try await getPreviousMessagesForChat(chat,
                                                                         threadHash: threadHash,
                                                                         fetchLimit: fetchLimit,
                                                                         isRead: false,
                                                                         for: user)
                if let i = chunkMessages.firstIndex(where: { $0.displayInfo.id == message.displayInfo.id }) {
                    let missingMessages = Array(chunkMessages[..<i])
                    messages.append(contentsOf: missingMessages)
                    break
                } else {
                    messages.append(contentsOf: chunkMessages)
                    guard !chunkMessages.isEmpty else { break }
                    
                    let messageMetadata: PushEnvironment.MessageServiceMetadata = try decodeServiceMetadata(from: chunkMessages.last!.serviceMetadata)
                    guard let hash = messageMetadata.link else { break }
                    threadHash = hash
                }
            }
            
            return messages
        }
        
    }
    
    private func getPreviousMessagesForChat(_ chat: MessagingChat,
                                            threadHash: String,
                                            fetchLimit: Int,
                                            isRead: Bool,
                                            for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage] {
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let env = getCurrentPushEnvironment()
        let pushMessages = try await Push.PushChat.History(threadHash: threadHash,
                                                           limit: fetchLimit,
                                                           pgpPrivateKey: "",
                                                           toDecrypt: false,
                                                           env: env)
        
        let messages = pushMessages.compactMap({ PushEntitiesTransformer.convertPushMessageToChatMessage($0,
                                                                                                         in: chat,
                                                                                                         pgpKey: pgpPrivateKey,
                                                                                                         isRead: isRead) })
        return messages
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat,
                     by user: MessagingChatUserProfile) async throws -> MessagingChatMessage {
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)

        switch chat.displayInfo.type {
        case .private(let otherUserDetails):
            let receiver = otherUserDetails.otherUser
            let sendOptions = try await buildPushSendOptions(for: messageType,
                                                        receiver: receiver.wallet,
                                                        by: user)
            let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
            let isConversationFirst = chatMetadata.threadHash == nil
            
            let message: Push.Message
            if isConversationFirst {
                message = try await Push.PushChat.sendIntent(sendOptions)
            } else {
                message = try await Push.PushChat.sendMessage(sendOptions)
            }
            
            guard let chatMessage = PushEntitiesTransformer.convertPushMessageToChatMessage(message,
                                                                                            in: chat,
                                                                                            pgpKey: pgpPrivateKey,
                                                                                            isRead: true) else { throw PushMessagingAPIServiceError.failedToConvertPushMessage }
            
            return chatMessage
        case .group(let groupDetails):
            throw PushMessagingAPIServiceError.sendMessageInGroupChatNotSupported  // <GROUP_CHAT> Group chats not supported for now
        }
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType,
                     to userInfo: MessagingChatUserDisplayInfo,
                     by user: MessagingChatUserProfile) async throws -> (MessagingChat, MessagingChatMessage) {
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let sendOptions = try await buildPushSendOptions(for: messageType,
                                                         receiver: userInfo.wallet,
                                                         by: user)
        let message = try await Push.PushChat.sendIntent(sendOptions)
        let pushChats = try await getPushChatsForUser(user, page: 1, limit: 4, isRequests: false)
        
        guard let pushChat = pushChats.first(where: { $0.threadhash == message.link }),// TODO: - cid instead of link
              let chat = PushEntitiesTransformer.convertPushChatToChat(pushChat,
                                                                       userId: user.id,
                                                                       userWallet: user.wallet,
                                                                       isApproved: true),
              let chatMessage = PushEntitiesTransformer.convertPushMessageToChatMessage(message,
                                                                                        in: chat,
                                                                                        pgpKey: pgpPrivateKey,
                                                                                        isRead: true) else {
            throw PushMessagingAPIServiceError.failedToConvertPushMessage
        }
        
        return (chat, chatMessage)
    }
    
    func makeChatRequest(_ chat: MessagingChat,
                         approved: Bool,
                         by user: MessagingChatUserProfile) async throws {
        guard approved else { throw PushMessagingAPIServiceError.declineRequestNotSupported }
        guard case .private(let otherUserDetails) = chat.displayInfo.type else { throw PushMessagingAPIServiceError.sendMessageInGroupChatNotSupported }
        
        let env = getCurrentPushEnvironment()
        let sender = chat.displayInfo.thisUserDetails
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)

        let approveOptions = Push.PushChat.ApproveOptions(fromAddress: sender.wallet ,
                                                          toAddress: otherUserDetails.otherUser.wallet,
                                                          privateKey: pgpPrivateKey,
                                                          env: env)
        _ = try await Push.PushChat.approve(approveOptions)
    }
    
    // Channels
    func getSubscribedChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        let subscribedChannelsIds = try await pushRESTService.getSubscribedChannelsIds(for: user.wallet)
        guard !subscribedChannelsIds.isEmpty else { return [] }
        
        var channels = [PushChannel?]()
        await withTaskGroup(of: PushChannel?.self, body: { group in
            for id in subscribedChannelsIds {
                group.addTask {
                    try? await self.pushRESTService.getChannelDetails(for: id)
                }
            }
            
            for await channel in group {
                channels.append(channel)
            }
        })
        
        return channels.compactMap({ $0 }).map({ PushEntitiesTransformer.convertPushChannelToMessagingChannel($0,
                                                                                                              userId: user.id) })
    }
    
    func getNotificationsInboxFor(wallet: HexAddress,
                                  page: Int,
                                  limit: Int,
                                  isSpam: Bool) async throws -> [MessagingNewsChannelFeed] {
        let inbox = try await pushRESTService.getNotificationsInbox(for: wallet, page: page, limit: limit, isSpam: isSpam)
        
        return inbox.map({ PushEntitiesTransformer.convertPushInboxToChannelFeed($0) })
    }
    
    func getFeedFor(channel: MessagingNewsChannel,
                    page: Int,
                    limit: Int) async throws -> [MessagingNewsChannelFeed] {
        let feed = try await pushRESTService.getChannelFeed(for: channel.channel, page: page, limit: limit)
        
        return feed.map({ PushEntitiesTransformer.convertPushInboxToChannelFeed($0) })
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    func storePGPKeyFromPushUserIfNeeded(_ pushUser: Push.PushUser, domain: DomainItem) async throws {
        let wallet = try await domain.getAddress()
        guard KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet) == nil else { return } // Already saved
        
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: pushUser.encryptedPrivateKey,
                                                             signer: domain)
        KeychainPGPKeysStorage.instance.savePGPKey(pgpPrivateKey,
                                                   forIdentifier: wallet)
    }
    
    func getPGPPrivateKeyFor(user: MessagingChatUserProfile) async throws -> String {
        let wallet = user.wallet
        if let key = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet) {
            return key
        }
        
        let chatMetadata: PushEnvironment.UserProfileServiceMetadata = try decodeServiceMetadata(from: user.serviceMetadata)
        let domain = try await getAnyDomainItem(for: wallet)
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: chatMetadata.encryptedPrivateKey, signer: domain)
        KeychainPGPKeysStorage.instance.savePGPKey(pgpPrivateKey, forIdentifier: wallet)
        return pgpPrivateKey
    }
    
    func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        let wallet = wallet.normalized
        guard let domain = await appContext.dataAggregatorService.getDomainItems().first(where: { $0.ownerWallet == wallet }) else {
            throw PushMessagingAPIServiceError.noDomainForWallet
        }
        
        return domain
    }
    
    func buildPushSendOptions(for messageType: MessagingChatMessageDisplayType,
                                 receiver: String,
                                 by user: MessagingChatUserProfile) async throws -> Push.PushChat.SendOptions {
        let env = getCurrentPushEnvironment()
        let pushMessageContent = try getPushMessageContentFrom(displayType: messageType)
        let pushMessageType = getPushMessageTypeFrom(displayType: messageType)
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        
        let sendOptions = Push.PushChat.SendOptions(messageContent: pushMessageContent,
                                                    messageType: pushMessageType.rawValue,
                                                    receiverAddress: receiver,
                                                    account: user.wallet,
                                                    pgpPrivateKey: pgpPrivateKey,
                                                    env: env)
        return sendOptions
    }
    
    func getCurrentPushEnvironment() -> Push.ENV {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .STAGING : .PROD
    }
    
    func decodeServiceMetadata<T: Codable>(from data: Data?) throws -> T {
        guard let data else {
            throw PushMessagingAPIServiceError.failedToDecodeServiceData
        }
        guard let serviceMetadata = T.objectFromData(data) else {
            throw PushMessagingAPIServiceError.failedToDecodeServiceData
        }
        
        return serviceMetadata
    }
   
    func getPushMessageContentFrom(displayType: MessagingChatMessageDisplayType) throws -> String {
        switch displayType {
        case .text(let details):
            return details.text
        case .imageBase64(let details):
            let entity = PushEnvironment.PushImageContentResponse(content: details.base64)
            guard let jsonString = entity.jsonString() else { throw PushMessagingAPIServiceError.failedToPrepareMessageContent }
            return jsonString
        }
    }
    
    func getPushMessageTypeFrom(displayType: MessagingChatMessageDisplayType) -> PushMessageType {
        switch displayType {
        case .text:
            return .text
        case .imageBase64:
            return .image
        }
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    enum PushMessageType: String {
        case text = "Text"
        case image = "Image"
        case file = "File"
        case gif = "GIF"
    }
}

// MARK: - Open methods
extension PushMessagingAPIService {
    enum PushMessagingAPIServiceError: Error {
        case noDomainForWallet
        case noOwnerWalletInDomain
        case failedToGetPushUser
        case incorrectDataState
        
        case failedToDecodeServiceData
        case failedToConvertPushMessage
        case sendMessageInGroupChatNotSupported
        case declineRequestNotSupported
        case failedToPrepareMessageContent
    }
}

extension DomainItem: Push.Signer {
    func getEip191Signature(message: String) async throws -> String {
        try await self.personalSign(message: message)
    }
    
    func getAddress() async throws -> String {
        guard let ownerWallet else { throw PushMessagingAPIService.PushMessagingAPIServiceError.noOwnerWalletInDomain }
        
        return getETHAddress() ?? ownerWallet
    }
}
