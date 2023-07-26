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
                                    env: Push.ENV,
                                    pgpPrivateKey: String) async throws -> [MessagingChatMessage]
}

final class PushMessagingAPIService {
    
    private let pushRESTService = PushRESTAPIService()
    private let pushHelper = PushServiceHelper()
    private let messagingHelper = MessagingAPIServiceHelper()
    private let dataProvider: PushMessagingAPIServiceDataProvider

    init(dataProvider: PushMessagingAPIServiceDataProvider = DefaultPushMessagingAPIServiceDataProvider()) {
        self.dataProvider = dataProvider
    }
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
        if !avatar.trimmed.isEmpty {
            updatedProfile.picture = avatar
        }
        updatedProfile.blockedUsersList = updatedProfile.blockedUsersList ?? []
        
        try await PushUser.updateUserProfile(account: account, pgpPrivateKey: pgpKey, newProfile: updatedProfile, env: env)
    }
    
    // Chats
    var isSupportChatsListPagination: Bool { true }
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
                            before message: MessagingChatMessage?,
                            cachedMessages: [MessagingChatMessage],
                            fetchLimit: Int,
                            isRead: Bool,
                            for user: MessagingChatUserProfile,
                            filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
        guard let chatThreadHash = chatMetadata.threadHash else { return [] } // No messages in chat yet
        
        var fetchLimitToUse = fetchLimit
        var threadHash = chatThreadHash
        var messagesToKeep = [MessagingChatMessage]()
        let env = getCurrentPushEnvironment()
        let pgpPrivateKey = try await getPGPPrivateKeyFor(user: user)

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
        
        let remoteMessages = try await dataProvider.getPreviousMessagesForChat(chat,
                                                                               threadHash: threadHash,
                                                                               fetchLimit: fetchLimitToUse,
                                                                               isRead: isRead,
                                                                               filesService: filesService,
                                                                               env: env,
                                                                               pgpPrivateKey: pgpPrivateKey)
        
        return messagesToKeep + remoteMessages
    }
    
    func loadRemoteContentFor(_ message: MessagingChatMessage,
                              serviceData: Data,
                              filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType {
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
        let messageMetadata: PushEnvironment.MessageServiceMetadata = try! decodeServiceMetadata(from: message.serviceMetadata)
        return messageMetadata.link
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
        
        let userMetadata: PushEnvironment.UserProfileServiceMetadata = try decodeServiceMetadata(from: user.serviceMetadata)
        let domain = try await getAnyDomainItem(for: wallet)
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: userMetadata.encryptedPrivateKey, signer: domain)
        KeychainPGPKeysStorage.instance.savePGPKey(pgpPrivateKey, forIdentifier: wallet)
        return pgpPrivateKey
    }
    
    func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        try await messagingHelper.getAnyDomainItem(for: wallet)
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
        pushHelper.getCurrentPushEnvironment()
    }
    
    func decodeServiceMetadata<T: Codable>(from data: Data?) throws -> T {
        try messagingHelper.decodeServiceMetadata(from: data)
    }
   
    func getPushMessageContentFrom(displayType: MessagingChatMessageDisplayType) throws -> String {
        switch displayType {
        case .text(let details):
            return details.text
        case .imageBase64(let details):
            let entity = PushEnvironment.PushMessageContentResponse(content: details.base64)
            guard let jsonString = entity.jsonString() else { throw PushMessagingAPIServiceError.failedToPrepareMessageContent }
            return jsonString
        case .imageData(let details):
            guard let base64 = details.image.base64String else { throw PushMessagingAPIServiceError.unsupportedType }
            let preparedBase64 = Base64DataTransformer.addingImageIdentifier(to: base64)
            let imageBase64TypeDetails = MessagingChatMessageImageBase64TypeDisplayInfo(base64: preparedBase64)
            return try getPushMessageContentFrom(displayType: .imageBase64(imageBase64TypeDetails))
        case .unknown, .remoteContent:
            throw PushMessagingAPIServiceError.unsupportedType
        }
    }
    
    func getPushMessageTypeFrom(displayType: MessagingChatMessageDisplayType) throws -> PushMessageType {
        switch displayType {
        case .text:
            return .text
        case .imageBase64, .imageData:
            return .image
        case .unknown, .remoteContent:
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
    enum PushMessagingAPIServiceError: String, LocalizedError {
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
        case actionNotSupported
        
        public var errorDescription: String? { rawValue }

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
        try getETHAddressThrowing()
    }
}

final class DefaultPushMessagingAPIServiceDataProvider: PushMessagingAPIServiceDataProvider {
    func getPreviousMessagesForChat(_ chat: MessagingChat,
                                    threadHash: String,
                                    fetchLimit: Int,
                                    isRead: Bool,
                                    filesService: MessagingFilesServiceProtocol,
                                    env: Push.ENV,
                                    pgpPrivateKey: String) async throws -> [MessagingChatMessage] {
        
        let pushMessages = try await Push.PushChat.History(threadHash: threadHash,
                                                           limit: fetchLimit,
                                                           pgpPrivateKey: "", // Get encrypted messages
                                                           toDecrypt: false,
                                                           env: env)
        
        let messages = pushMessages.compactMap({ PushEntitiesTransformer.convertPushMessageToChatMessage($0,
                                                                                                         in: chat,
                                                                                                         pgpKey: pgpPrivateKey,
                                                                                                         isRead: isRead,
                                                                                                         filesService: filesService) })
        return messages
    }
}
