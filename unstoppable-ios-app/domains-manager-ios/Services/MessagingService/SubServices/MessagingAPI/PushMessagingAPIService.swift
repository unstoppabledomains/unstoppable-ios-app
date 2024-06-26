//
//  PushMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import Push

protocol PushMessagingAPIServiceDataProvider {
    func getPreviousMessagesForChat(_ chat: MessagingChat,
                                    threadHash: String,
                                    fetchLimit: Int,
                                    isRead: Bool,
                                    filesService: MessagingFilesServiceProtocol,
                                    for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage]
}

final class PushMessagingAPIService {
    
    private let pushRESTService = PushRESTAPIService()
    private let dataProvider: PushMessagingAPIServiceDataProvider
    private let isRegularChatsEnabled = false
    let capabilities = MessagingServiceCapabilities(canContactWithoutProfile: true,
                                                    canBlockUsers: true,
                                                    isSupportChatsListPagination: true,
                                                    isRequiredToReloadLastMessage: false)

    init(dataProvider: PushMessagingAPIServiceDataProvider = DefaultPushMessagingAPIServiceDataProvider()) {
        self.dataProvider = dataProvider
    }
}

// MARK: - MessagingAPIServiceProtocol
extension PushMessagingAPIService: MessagingAPIServiceProtocol {
    var serviceIdentifier: MessagingServiceIdentifier { .push }
    
    // User profile
    func getUserFor(wallet: WalletEntity) async throws -> MessagingChatUserProfile {
        let walletAddress = wallet.ethFullAddress
        let env = getCurrentPushEnvironment()
        
        guard let pushUser = try await PushUser.get(account: walletAddress, env: env) else {
            throw PushMessagingAPIServiceError.failedToGetPushUser
        }
        
        let userProfile = PushEntitiesTransformer.convertPushUserToChatUser(pushUser)
        try await storePGPKeyFromPushUserIfNeeded(pushUser, wallet: wallet)
        return userProfile
    }
    
    func createUser(for wallet: WalletEntity) async throws -> MessagingChatUserProfile {
        let env = getCurrentPushEnvironment()
        let pushUser = try await PushUser.create(options: .init(env: env,
                                                                signer: wallet,
                                                                version: .PGP_V3,
                                                                progressHook: nil))
        try await storePGPKeyFromPushUserIfNeeded(pushUser, wallet: wallet)
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
        if !avatar.trimmed.isEmpty {
            updatedProfile.picture = avatar
        }
        updatedProfile.blockedUsersList = updatedProfile.blockedUsersList ?? []
        
        try await PushUser.updateUserProfile(account: account, pgpPrivateKey: pgpKey, newProfile: updatedProfile, env: env)
    }
    
    // Chats
    func getChatsListForUser(_ user: MessagingChatUserProfile,
                               page: Int,
                               limit: Int) async throws -> [MessagingChat] {
        if isRegularChatsEnabled {
            let pushChats = try await getPushChatsForUser(user,
                                                          page: page,
                                                          limit: limit,
                                                          isRequests: false)
            
            let chats = try await transformPushChatsToChats(pushChats,
                                                            isApproved: true,
                                                            for: user)
            return chats
        } else {
            return []
        }
    }
    
    func getCommunitiesListForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingChat] {
        try await getBadgesCommunitiesListForUser(user)
    }
    
    private func getBadgesCommunitiesListForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingChat] {
        let domain = try await MessagingAPIServiceHelper.getAnyDomainItem(for: user.normalizedWallet)
        let badgesList = try await NetworkService().fetchBadgesInfo(for: domain)
        let pushUser = try await getPushUser(of: user)
        let blockedUsersList = pushUser.profile.blockedUsersList ?? []
        let badges = badgesList.badges
        var chats: [MessagingChat] = []
        
        await withTaskGroup(of: Optional<MessagingChat>.self, body: { group in
            for badge in badges {
                group.addTask {
                    if let groupChatId = badge.groupChatId,
                       let chat = try? await self.getGroupChatBy(groupChatId: groupChatId,
                                                                 user: user,
                                                                 badgeInfo: badge,
                                                                 blockedUsersList: blockedUsersList) {
                        return chat
                    } else {
                        let chat = PushEntitiesTransformer.buildEmptyCommunityChatFor(badgeInfo: badge,
                                                                                      user: user,
                                                                                      blockedUsersList: blockedUsersList)
                        return chat
                    }
                }
            }
            
            for await chat in group {
                guard let chat else { continue }
                chats.append(chat)
            }
        })
    
        return chats
    }
    
    private func getGroupChatBy(groupChatId: String,
                                user: MessagingChatUserProfile,
                                badgeInfo: BadgesInfo.BadgeInfo,
                                blockedUsersList: [String]) async throws -> MessagingChat {
        let env = getCurrentPushEnvironment()
        guard let pushGroup = (try await Push.PushChat.getGroup(chatId: groupChatId, env: env)) else {
            throw PushMessagingAPIServiceError.groupChatWithGivenIdNotFound
        }
        
        let threadHash = try? await self.pushRESTService.getChatThreadHash(for: user.wallet, chatId: groupChatId)
        let pushChat = PushChat(pushGroup: pushGroup, threadHash: threadHash)
        let communityDetails: PushEntitiesTransformer.CommunityChatDetails = .init(badgeInfo: badgeInfo,
                                                                                   blockedUsersList: blockedUsersList)
        guard let chat = PushEntitiesTransformer.convertPushChatToChat(pushChat,
                                                                       userId: user.id,
                                                                       userWallet: user.wallet,
                                                                       isApproved: true,
                                                                       communityChatDetails: communityDetails) else {
            throw PushMessagingAPIServiceError.failedToConvertPushChat
        }
        return chat
    }
    
    func joinCommunityChat(_ communityChat: MessagingChat,
                           by user: MessagingChatUserProfile) async throws -> MessagingChat {
        let userWallet = communityChat.displayInfo.thisUserDetails.wallet
        switch communityChat.displayInfo.type {
        case .community(let details):
            /// Check user is not yet joined
            guard !details.isJoined else { return communityChat }
            
            switch details.type {
            case .badge(let badgeInfo):
                let privateKey = try await getPGPPrivateKeyFor(user: user)
                let signature = try Pgp.sign(message: badgeInfo.code, privateKey: privateKey)
                let pushUser = try await getPushUser(of: user)
                let blockedUsersList = pushUser.profile.blockedUsersList ?? []
                let approveResponse = try await NetworkService().joinBadgeCommunity(badge: badgeInfo,
                                                                                    by: userWallet,
                                                                                    signature: signature)
                let groupChat = try await getGroupChatBy(groupChatId: approveResponse.groupChatId,
                                                         user: user,
                                                         badgeInfo: badgeInfo,
                                                         blockedUsersList: blockedUsersList)
                let requests = try await getPushChatsForUser(user,
                                                            page: 1,
                                                            limit: 3,
                                                            isRequests: true)
                if requests.first(where: { $0.chatId == groupChat.id }) != nil {
                    try await makeChatRequest(groupChat, approved: true, by: user)
                }
                return groupChat
            }
        case .private, .group:
            throw PushMessagingAPIServiceError.actionNotSupported
        }
    }
    
    func leaveCommunityChat(_ communityChat: MessagingChat,
                            by user: MessagingChatUserProfile) async throws -> MessagingChat {
        let userWallet = communityChat.displayInfo.thisUserDetails.wallet
        switch communityChat.displayInfo.type {
        case .community(let details):
            /// Check user is currently joined
            guard details.isJoined else { return communityChat }
            
            switch details.type {
            case .badge(let badgeInfo):
                let privateKey = try await getPGPPrivateKeyFor(user: user)
                let signature = try Pgp.sign(message: badgeInfo.code, privateKey: privateKey)
                let pushUser = try await getPushUser(of: user)
                let blockedUsersList = pushUser.profile.blockedUsersList ?? []
                
                try await NetworkService().leaveBadgeCommunity(badge: badgeInfo,
                                                               by: userWallet,
                                                               signature: signature)
                let groupChat = try await getGroupChatBy(groupChatId: communityChat.displayInfo.id,
                                                         user: user,
                                                         badgeInfo: badgeInfo,
                                                         blockedUsersList: blockedUsersList)
                return groupChat
            }
        case .private, .group:
            throw PushMessagingAPIServiceError.actionNotSupported
        }
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
        if isRegularChatsEnabled {
            let pushChats = try await getPushChatsForUser(user,
                                                          page: page,
                                                          limit: limit,
                                                          isRequests: true)
            
            return try await transformPushChatsToChats(pushChats,
                                                       isApproved: false,
                                                       for: user)
        } else {
            return []
        }
    }
    
    private func transformPushChatsToChats(_ pushChats: [PushChat],
                                           isApproved: Bool,
                                           for user: MessagingChatUserProfile) async throws -> [MessagingChat] {
        var chats = [MessagingChat]()
        
        try await withThrowingTaskGroup(of: MessagingChat.self, body: { group in
            for pushChat in pushChats {
                if let chat = PushEntitiesTransformer.convertPushChatToChat(pushChat,
                                                                            userId: user.id,
                                                                            userWallet: user.wallet,
                                                                            isApproved: isApproved) {
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
    
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus {
        .unblocked
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
        case .group, .community:
            return .unblocked
        }
    }
    
    func setUser(in chat: MessagingChat,
                 blocked: Bool,
                 by user: MessagingChatUserProfile) async throws {
        switch chat.displayInfo.type {
        case .private(let details):
            let otherUserAddress = details.otherUser.wallet
            try await setOtherUserAddress(otherUserAddress, blocked: blocked, by: user)
        case .group, .community:
            throw PushMessagingAPIServiceError.blockUserInGroupChatsNotSupported
        }
    }
    
    func setUser(_ otherUser: MessagingChatUserDisplayInfo,
                 in groupChat: MessagingChat,
                 blocked: Bool,
                 by user: MessagingChatUserProfile) async throws {
        switch groupChat.displayInfo.type {
        case .private:
            return
        case .group, .community:
            let otherUserAddress = otherUser.wallet
            try await setOtherUserAddress(otherUserAddress, blocked: blocked, by: user)
        }
    }
    
    func block(chats: [MessagingChat],
               by user: MessagingChatUserProfile) async throws {
        throw PushMessagingAPIServiceError.actionNotSupported /// Since we work with XMTP chats only ATM
    }
    
    func isAbleToContactAddress(_ address: String,
                                by user: MessagingChatUserProfile) async throws -> Bool {
        true
    }
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            before message: MessagingChatMessage?,
                            cachedMessages: [MessagingChatMessage],
                            fetchLimit: Int,
                            isRead: Bool,
                            for user: MessagingChatUserProfile,
                            filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
        guard let chatThreadHash = chatMetadata.threadHash else { return [] } // No messages in chat yet
        
        var message = message
        var fetchLimitToUse = fetchLimit
        var threadHash = chatThreadHash
        var messagesToKeep = [MessagingChatMessage]()

        if let message {
            guard let currentMessageLink = getLinkFrom(message: message) else { return [] } // Request messages before first in chat
            threadHash = currentMessageLink
        }
        let result = try messageToLoadDescriptionFrom(in: cachedMessages, starting: threadHash)
        switch result {
        case .noCachedMessages:
            Void()
        case .reachedFirstMessageInChat:
            messagesToKeep = cachedMessages
        case .messageToLoad(let missingMessageThreadHash):
            threadHash = missingMessageThreadHash.threadHash
            fetchLimitToUse -= missingMessageThreadHash.offset
            messagesToKeep = missingMessageThreadHash.messagesToKeep
        }
        
        
        if messagesToKeep.count >= fetchLimit {
            return messagesToKeep
        }
        if messagesToKeep.last?.displayInfo.isFirstInChat == true {
            return messagesToKeep
        }
        
        var remoteMessages = try await dataProvider.getPreviousMessagesForChat(chat,
                                                                               threadHash: threadHash,
                                                                               fetchLimit: fetchLimitToUse,
                                                                               isRead: isRead,
                                                                               filesService: filesService,
                                                                               for: user)
        assignPreviousMessagesIn(messages: &remoteMessages)
        
        return messagesToKeep + remoteMessages
    }
    
    func loadRemoteContentFor(_ message: MessagingChatMessage,
                              user: MessagingChatUserProfile,
                              serviceData: Data,
                              filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType {
        let embeddedMediaContent = try PushEnvironment.PushMessageMediaEmbeddedContent.objectFromDataThrowing(serviceData)
        let url = embeddedMediaContent.content
        if let image = await appContext.imageLoadingService.loadImage(from: .url(url, maxSize: nil),
                                                                      downsampleDescription: .max) {
            let data = try image.gifDataRepresentation()
            let imageDisplayInfo = MessagingChatMessageImageDataTypeDisplayInfo(data: data,
                                                                                image: image)
            return .imageData(imageDisplayInfo)
        }
        throw PushMessagingAPIServiceError.actionNotSupported
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
        case .community(let details):
            return !details.isPublic
        }
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat,
                     by user: MessagingChatUserProfile,
                     filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage {
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let env = PushServiceHelper.getCurrentPushEnvironment()

        func convertPushMessageToChatMessage(_ message: Push.Message) async throws -> MessagingChatMessage {
            guard let chatMessage = await PushEntitiesTransformer.convertPushMessageToChatMessage(message,
                                                                                                  in: chat,
                                                                                                  pgpKey: pgpPrivateKey,
                                                                                                  isRead: true,
                                                                                                  filesService: filesService,
                                                                                                  env: env) else { throw PushMessagingAPIServiceError.failedToConvertPushMessage }
            
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
            
            return try await convertPushMessageToChatMessage(message)
        case .group, .community:
            let receiver = PushEntitiesTransformer.getPushChatIdFrom(chat: chat)
            let sendOptions = try await buildPushSendOptions(for: messageType,
                                                             receiver: receiver,
                                                             by: user)
            let message = try await Push.PushChat.sendMessage(sendOptions)
            return try await convertPushMessageToChatMessage(message)
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
        let env = PushServiceHelper.getCurrentPushEnvironment()

        guard let pushChat = pushChats.first(where: { $0.threadhash == message.cid }) else { throw PushMessagingAPIServiceError.failedToConvertPushMessage }
             
        guard let chat = PushEntitiesTransformer.convertPushChatToChat(pushChat,
                                                                       userId: user.id,
                                                                       userWallet: user.wallet,
                                                                       isApproved: true),
              let chatMessage = await PushEntitiesTransformer.convertPushMessageToChatMessage(message,
                                                                                              in: chat,
                                                                                              pgpKey: pgpPrivateKey,
                                                                                              isRead: true,
                                                                                              filesService: filesService,
                                                                                              env: env) else {
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
        case .group, .community:
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
}

// MARK: - Get message related
private extension PushMessagingAPIService {
    func messageToLoadDescriptionFrom(in cachedMessages: [MessagingChatMessage], starting startId: String) throws -> MessageToLoadFromResult {
        guard !cachedMessages.isEmpty else { return .noCachedMessages }
        guard cachedMessages.first?.displayInfo.id == startId else {
            return .messageToLoad(MessageToLoad(threadHash: startId, offset: 0, messagesToKeep: []))
        }
        
        var currentMessage = cachedMessages.first!
        var offset = 1
        var messagesToKeep: [MessagingChatMessage] = [currentMessage]
        
        for i in 1..<cachedMessages.count {
            let previousMessage = cachedMessages[i]
            guard let currentMessageLink = getLinkFrom(message: currentMessage) else { return .reachedFirstMessageInChat }
            if currentMessageLink != previousMessage.displayInfo.id {
                return .messageToLoad(MessageToLoad(threadHash: currentMessageLink, offset: offset, messagesToKeep: messagesToKeep))
            }
            offset += 1
            currentMessage = previousMessage
            messagesToKeep.append(previousMessage)
        }
        
        guard let currentMessageLink = getLinkFrom(message: currentMessage) else { return .reachedFirstMessageInChat }
        
        return .messageToLoad(MessageToLoad(threadHash: currentMessageLink, offset: offset, messagesToKeep: messagesToKeep))
    }
    
    enum MessageToLoadFromResult {
        case noCachedMessages
        case reachedFirstMessageInChat
        case messageToLoad(MessageToLoad)
    }
    
    struct MessageToLoad {
        let threadHash: String
        let offset: Int
        let messagesToKeep: [MessagingChatMessage]
    }
    
    func getLinkFrom(message: MessagingChatMessage) -> String? {
        let messageMetadata: PushEnvironment.MessageServiceMetadata? = try? decodeServiceMetadata(from: message.serviceMetadata)
        return messageMetadata?.link?.replacingOccurrences(of: "previous:", with: "")
    }
    
    func assignPreviousMessagesIn(messages: inout [MessagingChatMessage]) {
        guard !messages.isEmpty else { return }
        
        for i in 1..<messages.count {
            setPreviousMessageId(messages[i].displayInfo.id, to: &messages[i-1])
        }
    }
    
    func setPreviousMessageId(_ previousMessageId: String, to message: inout MessagingChatMessage) {
        guard var messageMetadata: PushEnvironment.MessageServiceMetadata = try? MessagingAPIServiceHelper.decodeServiceMetadata(from: message.serviceMetadata) else { return }
        
        messageMetadata.link = previousMessageId
        message.serviceMetadata = messageMetadata.jsonData()
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    func getPushUser(of user: MessagingChatUserProfile) async throws -> Push.PushUser {
        let env = getCurrentPushEnvironment()
        let account = user.wallet
        guard let pushUser = try await PushUser.get(account: account, env: env) else {
            throw PushMessagingAPIServiceError.failedToGetPushUser
        }
        return pushUser
    }
    
    func storePGPKeyFromPushUserIfNeeded(_ pushUser: Push.PushUser, wallet: WalletEntity) async throws {
        let walletAddress = wallet.ethFullAddress
        guard KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: walletAddress) == nil else { return } // Already saved
        
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: pushUser.encryptedPrivateKey,
                                                             signer: wallet)
        KeychainPGPKeysStorage.instance.savePGPKey(pgpPrivateKey,
                                                   forIdentifier: walletAddress)
    }
    
    func getPGPPrivateKeyFor(user: MessagingChatUserProfile) async throws -> String {
        try await PushServiceHelper.getPGPPrivateKeyFor(user: user)
    }
    
    func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        try await MessagingAPIServiceHelper.getAnyDomainItem(for: wallet)
    }
    
    func buildPushSendOptions(for messageType: MessagingChatMessageDisplayType,
                              receiver: String,
                              by user: MessagingChatUserProfile) async throws -> Push.PushChat.SendOptions {
        let env = getCurrentPushEnvironment()
        let pushMessageContent = try await getPushMessageContentFrom(displayType: messageType,
                                                                     by: user)
        let pushMessageType = try getPushMessageTypeFrom(displayType: messageType)
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)
        let reference = getPushMessageReferenceFrom(displayType: messageType)
        
        let sendOptions = Push.PushChat.SendOptions(messageContent: pushMessageContent,
                                                    messageType: pushMessageType.rawValue,
                                                    receiverAddress: receiver,
                                                    account: user.wallet,
                                                    pgpPrivateKey: pgpPrivateKey,
                                                    refrence: reference,
                                                    env: env)
        return sendOptions
    }
    
    func getCurrentPushEnvironment() -> Push.ENV {
        PushServiceHelper.getCurrentPushEnvironment()
    }
    
    func decodeServiceMetadata<T: Codable>(from data: Data?) throws -> T {
        try MessagingAPIServiceHelper.decodeServiceMetadata(from: data)
    }
   
    func getPushMessageContentFrom(displayType: MessagingChatMessageDisplayType,
                                   by user: MessagingChatUserProfile) async throws -> String {
        switch displayType {
        case .text(let details):
            return details.text
        case .imageBase64(let details):
            guard let data = Data(base64Encoded: details.base64) else { throw PushMessagingAPIServiceError.failedToPrepareMessageContent }
            return try await getImagePushMessageContentFrom(data: data, by: user)
        case .imageData(let details):
            return try await getImagePushMessageContentFrom(data: details.data, by: user)
        case .reaction(let details):
            return details.content
        case .reply(let info):
            let replyType = info.contentType
            if case .text = replyType {
                return try await getPushMessageContentFrom(displayType: replyType,
                                                           by: user)
            }
            throw PushMessagingAPIServiceError.canReplyOnlyWithText
        case .unknown, .remoteContent, .unsupported:
            throw PushMessagingAPIServiceError.unsupportedType
        }
    }
    
    func getImagePushMessageContentFrom(data: Data,
                                        by user: MessagingChatUserProfile) async throws -> String {
        let wallet = user.wallet
        let url = try await MessagingAPIServiceHelper.uploadDataToWeb3Storage(data,
                                                                              ofType: "image/png",
                                                                              by: wallet)
        return url.absoluteString
    }
    
    func getPushMessageReferenceFrom(displayType: MessagingChatMessageDisplayType) -> String? {
        switch displayType {
        case .reaction(let details):
            return details.messageId
        case .reply(let info):
            return info.messageId
        case .text, .imageBase64, .imageData, .unknown, .remoteContent, .unsupported:
            return nil
        }
    }
    
    func getPushMessageTypeFrom(displayType: MessagingChatMessageDisplayType) throws -> PushMessageType {
        switch displayType {
        case .text:
            return .text
        case .reaction:
            return .reaction
        case .imageBase64, .imageData:
            return .mediaEmbed
        case .reply:
            return .reply
        case .unknown, .remoteContent, .unsupported:
            throw PushMessagingAPIServiceError.unsupportedType
        }
    }
    
    func setOtherUserAddress(_ otherUserAddress: String, blocked: Bool, by user: MessagingChatUserProfile) async throws {
        let env = getCurrentPushEnvironment()
        let account = user.wallet
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
    }
}

// MARK: - Open methods
extension PushMessagingAPIService {
    enum PushMessagingAPIServiceError: String, LocalizedError {
        case noDomainForWallet
        case noOwnerWalletInDomain
        case failedToGetPushUser
        case incorrectDataState
        case blockUserInGroupChatsNotSupported
        case unsupportedType
        case groupChatWithGivenIdNotFound
        case canReplyOnlyWithText
        
        case failedToDecodeServiceData
        case failedToConvertPushChat
        case failedToConvertPushMessage
        case declineRequestNotSupported
        case failedToPrepareMessageContent
        case actionNotSupported
        
        public var errorDescription: String? { rawValue }

    }
}

extension WalletEntity: Push.Signer, Push.TypedSigner {
    func getEip191Signature(message: String) async throws -> String {
        try await udWallet.getPersonalSignature(messageString: message)
    }
    
    func getEip712Signature(message: String) async throws -> String {
        try await udWallet.getSignTypedData(dataString: message)
    }
    
    func getAddress() async throws -> String {
        ethFullAddress
    }
}

final class DefaultPushMessagingAPIServiceDataProvider: PushMessagingAPIServiceDataProvider {
    func getPreviousMessagesForChat(_ chat: MessagingChat,
                                    threadHash: String,
                                    fetchLimit: Int,
                                    isRead: Bool,
                                    filesService: MessagingFilesServiceProtocol,
                                    for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage] {
        let env = PushServiceHelper.getCurrentPushEnvironment()
        let pgpPrivateKey = try await PushServiceHelper.getPGPPrivateKeyFor(user: user)
        let pushMessages = try await Push.PushChat.History(threadHash: threadHash,
                                                           limit: fetchLimit,
                                                           pgpPrivateKey: "", // Get encrypted messages
                                                           toDecrypt: false,
                                                           env: env)
        let messages = await PushEntitiesTransformer.convertPushMessagesToChatMessage(pushMessages,
                                                                                      in: chat,
                                                                                      pgpKey: pgpPrivateKey,
                                                                                      isRead: isRead,
                                                                                      filesService: filesService,
                                                                                      env: env)
        return messages
    }
}
