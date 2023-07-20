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
    
    func updateUserProfile(_ user: MessagingChatUserProfile,
                           name: String,
                           avatar: String) async throws {
        let env = getCurrentPushEnvironment()
        let account = user.wallet
        guard let pushUser = try await PushUser.get(account: account, env: env) else {
            throw PushMessagingAPIServiceError.failedToGetPushUser
        }
        
        let pgpKey = try await self.getPGPPrivateKeyFor(user: user)
        var updatedProfile = pushUser.profile
        updatedProfile.name = name
        updatedProfile.picture = avatar
        updatedProfile.blockedUsersList = updatedProfile.blockedUsersList ?? []
        
        try await PushUser.updateUserProfile(account: account, pgpPrivateKey: pgpKey, newProfile: updatedProfile, env: env)
    }
    
    // Chats
    func getChatsListForUser(_ user: MessagingChatUserProfile,
                               page: Int,
                               limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await getPushChatsForUser(user,
                                                      page: page,
                                                      limit: limit,
                                                      isRequests: false)
        
        return try await transformPushChatsToChats(pushChats,
                                                   isApproved: true,
                                                   for: user)
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
    
    private func getPublicKeysFor(pushChat: PushChat) async throws -> [String] {
        if let cachedKeys = PushPublicKeysStorage.instance.getCachedKeys(for: pushChat.chatId),
           !cachedKeys.publicKeys.isEmpty {
            return cachedKeys.publicKeys
        }
        
        var keys = [String]()
        if let groupInfo = pushChat.groupInformation {
            keys = groupInfo.members.compactMap { $0.publicKey }
        } else {
            let chatDids = pushChat.combinedDID.components(separatedBy: "_")
            guard chatDids.count == 2 else {
                return  []
            }
          
            let env = getCurrentPushEnvironment()
            if let anotherUser = try await PushUser.get(account: chatDids[0] , env: env),
               let senderUser = try await PushUser.get(account: chatDids[1], env: env) {
                keys = [senderUser.getPGPPublickey(), anotherUser.getPGPPublickey()]
            }
        }
        
        if !keys.isEmpty {
            PushPublicKeysStorage.instance.saveKeysHoldersInfo([.init(chatId: pushChat.chatId, publicKeys: keys)])
        }
        return keys
    }
    
    func getChatRequestsForUser(_ user: MessagingChatUserProfile,
                                  page: Int,
                                  limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await getPushChatsForUser(user,
                                                      page: page,
                                                      limit: limit,
                                                      isRequests: true)
        
        return try await transformPushChatsToChats(pushChats,
                                                   isApproved: false,
                                                   for: user)
    }
    
    private func transformPushChatsToChats(_ pushChats: [PushChat],
                                           isApproved: Bool,
                                           for user: MessagingChatUserProfile) async throws -> [MessagingChat] {
        var chats = [MessagingChat]()
        
        try await withThrowingTaskGroup(of: MessagingChat.self, body: { group in
            for pushChat in pushChats {
                let publicKeys = try await getPublicKeysFor(pushChat: pushChat)
                if let chat = PushEntitiesTransformer.convertPushChatToChat(pushChat,
                                                                            userId: user.id,
                                                                            userWallet: user.wallet,
                                                                            isApproved: isApproved,
                                                                            publicKeys: publicKeys) {
                    chats.append(chat)
                }
            }
            
            /// 2. Take values from group
            for try await chat in group {
                chats.append(chat)
            }
        })
        
        return chats
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus {
        func isPushUser(_ pushUser: Push.PushUser?, blockedBy otherPushUser: Push.PushUser?) -> Bool {
            if let blockedUsersList = otherPushUser?.profile.blockedUsersList,
               let pushUser {
                return blockedUsersList.contains(pushUser.wallets)
            }
            return false
        }
        
        switch chat.displayInfo.type {
        case .private(let details):
            let env = getCurrentPushEnvironment()

            async let thisUserProfileTask = PushUser.get(account: chat.displayInfo.thisUserDetails.wallet, env: env)
            async let otherUserProfileTask = PushUser.get(account: details.otherUser.wallet, env: env)
            
            let (thisUserProfile, otherUserProfile) = try await (thisUserProfileTask, otherUserProfileTask)
            
            let isThisUserBlockOtherUser = isPushUser(otherUserProfile, blockedBy: thisUserProfile)
            let isOtherUserBlockThisUser = isPushUser(thisUserProfile, blockedBy: otherUserProfile)
            if !isThisUserBlockOtherUser,
               !isOtherUserBlockThisUser {
                return .unblocked
            } else if isThisUserBlockOtherUser,
                      isOtherUserBlockThisUser {
                return .bothBlocked
            } else if isThisUserBlockOtherUser {
                return .otherUserIsBlocked
            } else {
                return .currentUserIsBlocked
            }
        case .group:
            return .unblocked
        }
    }
    
    func setUser(in chat: MessagingChat,
                 blocked: Bool,
                 by user: MessagingChatUserProfile) async throws {
        let env = getCurrentPushEnvironment()
        
        switch chat.displayInfo.type {
        case .private(let details):
            let account = chat.displayInfo.thisUserDetails.wallet
            let otherUserAddress = details.otherUser.wallet
            let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
            
            if blocked {
                try await PushUser.blockUsers(addressesToBlock: [otherUserAddress],
                                              account: account,
                                              pgpPrivateKey: pgpPrivateKey,
                                              env: env)
            } else {
                try await PushUser.unblockUsers(addressesToUnblock: [otherUserAddress],
                                                account: account,
                                                pgpPrivateKey: pgpPrivateKey,
                                                env: env)
            }
        case .group:
            throw PushMessagingAPIServiceError.blockUserInGroupChatsNotSupported
        }
    }
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            options: MessagingAPIServiceLoadMessagesOptions,
                            fetchLimit: Int,
                            for user: MessagingChatUserProfile,
                            filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        switch options {
        case .default:
            let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
            guard let threadHash = chatMetadata.threadHash else {
                return [] // NULL threadHash means there's no messages in the chat yet
            }
            return try await getPreviousMessagesForChat(chat,
                                                        threadHash: threadHash,
                                                        fetchLimit: fetchLimit,
                                                        isRead: true,
                                                        for: user, filesService: filesService)
        case .before(let message):
            let messageMetadata: PushEnvironment.MessageServiceMetadata = try decodeServiceMetadata(from: message.serviceMetadata)
            guard let threadHash = messageMetadata.link else {
                return []
            }
            return try await getPreviousMessagesForChat(chat,
                                                        threadHash: threadHash,
                                                        fetchLimit: fetchLimit,
                                                        isRead: true,
                                                        for: user, filesService: filesService)
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
                                                                         for: user, filesService: filesService)
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
                                            for user: MessagingChatUserProfile,
                                            filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        let env = getCurrentPushEnvironment()
        let pushMessages = try await Push.PushChat.History(threadHash: threadHash,
                                                           limit: fetchLimit,
                                                           pgpPrivateKey: "", // Get encrypted messages
                                                           toDecrypt: false,
                                                           env: env)
        
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let messages = pushMessages.compactMap({ PushEntitiesTransformer.convertPushMessageToChatMessage($0,
                                                                                                         in: chat,
                                                                                                         pgpKey: pgpPrivateKey,
                                                                                                         isRead: isRead,
                                                                                                         filesService: filesService) })
        return messages
    }
    
    func isMessagesEncryptedIn(chatType: MessagingChatType) async -> Bool {
        switch chatType {
        case .private(let details):
            let env = getCurrentPushEnvironment()
            
            /// Message will be encrypted in chat where both users has Push profile created
            return (try? await PushUser.get(account: details.otherUser.wallet, env: env)) != nil
        case .group(let details):
            /// Messages not encrypted in public group
            return !details.isPublic
        }
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat,
                     by user: MessagingChatUserProfile,
                     filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage {
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)

        func convertPushMessageToChatMessage(_ message: Push.Message) throws -> MessagingChatMessage {
            guard let chatMessage = PushEntitiesTransformer.convertPushMessageToChatMessage(message,
                                                                                            in: chat,
                                                                                            pgpKey: pgpPrivateKey,
                                                                                            isRead: true,
                                                                                            filesService: filesService) else { throw PushMessagingAPIServiceError.failedToConvertPushMessage }
            
            return chatMessage
        }
        
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
            
            return try convertPushMessageToChatMessage(message)
        case .group:
            let receiver = PushEntitiesTransformer.getPushChatIdFrom(chat: chat)
            let sendOptions = try await buildPushSendOptions(for: messageType,
                                                             receiver: receiver,
                                                             by: user)
            let message = try await Push.PushChat.sendMessage(sendOptions)
            return try convertPushMessageToChatMessage(message)
        }
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType,
                          to userInfo: MessagingChatUserDisplayInfo,
                          by user: MessagingChatUserProfile,
                          filesService: MessagingFilesServiceProtocol) async throws -> (MessagingChat, MessagingChatMessage) {
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let receiver = userInfo.wallet.ethChecksumAddress()
        let sendOptions = try await buildPushSendOptions(for: messageType,
                                                         receiver: receiver,
                                                         by: user)
        let message = try await Push.PushChat.sendIntent(sendOptions)
        let pushChats = try await getPushChatsForUser(user, page: 1, limit: 3, isRequests: false)
        
        guard let pushChat = pushChats.first(where: { $0.threadhash == message.cid }) else { throw PushMessagingAPIServiceError.failedToConvertPushMessage }
        let publicKeys = try await getPublicKeysFor(pushChat: pushChat)
             
        guard let chat = PushEntitiesTransformer.convertPushChatToChat(pushChat,
                                                                       userId: user.id,
                                                                       userWallet: user.wallet,
                                                                       isApproved: true,
                                                                       publicKeys: publicKeys),
              let chatMessage = PushEntitiesTransformer.convertPushMessageToChatMessage(message,
                                                                                        in: chat,
                                                                                        pgpKey: pgpPrivateKey,
                                                                                        isRead: true,
                                                                                        filesService: filesService) else {
            throw PushMessagingAPIServiceError.failedToConvertPushMessage
        }
        
        return (chat, chatMessage)
    }
    
    func makeChatRequest(_ chat: MessagingChat,
                         approved: Bool,
                         by user: MessagingChatUserProfile) async throws {
        guard approved else { throw PushMessagingAPIServiceError.declineRequestNotSupported }
        
        let env = getCurrentPushEnvironment()
        let approverAddress = chat.displayInfo.thisUserDetails.wallet
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let requesterAddress: String
        switch chat.displayInfo.type {
        case .private(let otherUserDetails):
            requesterAddress = otherUserDetails.otherUser.wallet
        case .group:
            requesterAddress = PushEntitiesTransformer.getPushChatIdFrom(chat: chat)
        }

        let approveOptions = Push.PushChat.ApproveOptions(requesterAddress: requesterAddress,
                                                          approverAddress: approverAddress,
                                                          privateKey: pgpPrivateKey,
                                                          env: env)
        _ = try await Push.PushChat.approve(approveOptions)
    }
    
    func leaveGroupChat(_ chat: MessagingChat,
                        by user: MessagingChatUserProfile) async throws {
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let chatId = PushEntitiesTransformer.getPushChatIdFrom(chat: chat)
        let env = getCurrentPushEnvironment()
        
        try await Push.PushChat.leaveGroup(chatId: chatId, userAddress: user.wallet,
                                           userPgpPrivateKey: pgpPrivateKey,
                                           env: env)
    }
    
    // Channels
    func getSubscribedChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        let subscribedChannelsIds = try await pushRESTService.getSubscribedChannelsIds(for: user.wallet)
        
        return try await getChannelsWithIds(Set(subscribedChannelsIds), isCurrentUserSubscribed: true, user: user)
    }
    
    func getSpamChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        let spamChannelIds = try await pushRESTService.getSpamChannelsIds(for: user.wallet)
        
        return try await getChannelsWithIds(Set(spamChannelIds), isCurrentUserSubscribed: false, user: user)
    }
    
    private func getChannelsWithIds(_ channelIds: Set<String>,
                                    isCurrentUserSubscribed: Bool,
                                    user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        guard !channelIds.isEmpty else { return [] }

        var channels = [PushChannel?]()
        await withTaskGroup(of: PushChannel?.self, body: { group in
            for id in channelIds {
                group.addTask {
                    try? await self.pushRESTService.getChannelDetails(for: id)
                }
            }
            
            for await channel in group {
                channels.append(channel)
            }
        })
        
        return channels.compactMap({ $0 }).map({ PushEntitiesTransformer.convertPushChannelToMessagingChannel($0,
                                                                                                              isCurrentUserSubscribed: isCurrentUserSubscribed,
                                                                                                              isSearchResult: false,
                                                                                                              userId: user.id) })
    }
    
    func getFeedFor(channel: MessagingNewsChannel,
                    page: Int,
                    limit: Int,
                    isRead: Bool) async throws -> [MessagingNewsChannelFeed] {
        let feed = try await pushRESTService.getChannelFeed(for: channel.channel, page: page, limit: limit)
        
        return feed.map({ PushEntitiesTransformer.convertPushInboxToChannelFeed($0,isRead: isRead) })
    }
    
    func searchForChannels(page: Int,
                           limit: Int,
                           searchKey: String,
                           for user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        guard !searchKey.trimmedSpaces.isEmpty else { return [] }
        let channels = try await pushRESTService.searchForChannels(page: page, limit: limit, query: searchKey)
        
        return channels.compactMap({ $0 }).map({ PushEntitiesTransformer.convertPushChannelToMessagingChannel($0,
                                                                                                              isCurrentUserSubscribed: false,
                                                                                                              isSearchResult: true,
                                                                                                              userId: user.id) })
    }
    
    func setChannel(_ channel: MessagingNewsChannel,
                    subscribed: Bool,
                    by user: MessagingChatUserProfile) async throws {
        
        let domain = try await getAnyDomainItem(for: user.normalizedWallet)
        let env = getCurrentPushEnvironment()
        
        let subscribeOptions = Push.PushChannel.SubscribeOption(signer: domain,
                                                              channelAddress: channel.channel,
                                                              env: env)
        if subscribed {
            _ = try await Push.PushChannel.subscribe(option: subscribeOptions)
        } else {
            _ = try await Push.PushChannel.unsubscribe(option: subscribeOptions)
        }
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
        let pushMessageType = try getPushMessageTypeFrom(displayType: messageType)
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
            let entity = PushEnvironment.PushMessageContentResponse(content: details.base64)
            guard let jsonString = entity.jsonString() else { throw PushMessagingAPIServiceError.failedToPrepareMessageContent }
            return jsonString
        case .unknown:
            throw PushMessagingAPIServiceError.unsupportedType
        }
    }
    
    func getPushMessageTypeFrom(displayType: MessagingChatMessageDisplayType) throws -> PushMessageType {
        switch displayType {
        case .text:
            return .text
        case .imageBase64:
            return .image
        case .unknown:
            throw PushMessagingAPIServiceError.unsupportedType
        }
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    enum PushMessageType: String {
        case text = "Text"
        case image = "Image"
        case video = "Video"
        case audio = "Audio"
        case file = "File"
        case gif = "GIF" // Deprecated, use mediaEmbed
        case mediaEmbed = "MediaEmbed"
        case meta = "Meta"
        case reply = "Reply"
    }
}

// MARK: - Open methods
extension PushMessagingAPIService {
    enum PushMessagingAPIServiceError: Error {
        case noDomainForWallet
        case noOwnerWalletInDomain
        case failedToGetPushUser
        case incorrectDataState
        case blockUserInGroupChatsNotSupported
        case unsupportedType
        
        case failedToDecodeServiceData
        case failedToConvertPushMessage
        case declineRequestNotSupported
        case failedToPrepareMessageContent
    }
}

extension DomainItem: Push.Signer, Push.TypedSinger {
    func getEip191Signature(message: String) async throws -> String {
        try await self.personalSign(message: message)
    }
    
    func getEip712Signature(message: String) async throws -> String {
        try await self.typedDataSign(message: message)
    }
    
    func getAddress() async throws -> String {
        guard let ownerWallet else { throw PushMessagingAPIService.PushMessagingAPIServiceError.noOwnerWalletInDomain }
        
        return getETHAddress() ?? ownerWallet
    }
}
