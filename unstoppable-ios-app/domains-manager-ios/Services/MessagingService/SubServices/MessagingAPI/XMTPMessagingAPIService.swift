//
//  XMTPMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import XMTP

protocol XMTPMessagingAPIServiceDataProvider {
    func getPreviousMessagesForChat(_ chat: MessagingChat,
                                    before: Date?,
                                    cachedMessages: [MessagingChatMessage],
                                    fetchLimit: Int,
                                    isRead: Bool,
                                    filesService: MessagingFilesServiceProtocol,
                                    for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage]
}

final class XMTPMessagingAPIService {
    
    private let blockedUsersStorage = XMTPBlockedUsersStorage.shared
    private let cachedDataHolder = CachedDataHolder()
    let capabilities = MessagingServiceCapabilities(canContactWithoutProfile: false,
                                                    canBlockUsers: true,
                                                    isSupportChatsListPagination: false,
                                                    isRequiredToReloadLastMessage: true)
    let dataProvider: XMTPMessagingAPIServiceDataProvider
    
    init(dataProvider: XMTPMessagingAPIServiceDataProvider = DefaultXMTPMessagingAPIServiceDataProvider()) {
        self.dataProvider = dataProvider
        Client.register(codec: AttachmentCodec())
        Client.register(codec: RemoteAttachmentCodec())
    }
    
}
 
// MARK: - MessagingAPIServiceProtocol
extension XMTPMessagingAPIService: MessagingAPIServiceProtocol {
    var serviceIdentifier: String { Constants.xmtpMessagingServiceIdentifier }

    func getUserFor(domain: DomainItem) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        
        let wallet = try domain.getETHAddressThrowing()
        guard KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) != nil else {
            throw XMTPServiceError.userNotCreatedYet
        }
        
        return try await createUser(for: domain) /// In XMTP same function responsible for either get or create profile
    }
    
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTP.Client.create(account: domain,
                                                  options: .init(api: .init(env: env,
                                                                            isSecure: true,
                                                                            appVersion: XMTPServiceSharedHelper.getXMTPVersion())))

        try storeKeysDataFromClientIfNeeded(client, domain: domain, env: env)
        let userProfile = XMTPEntitiesTransformer.convertXMTPClientToChatUser(client)
        return userProfile
    }
    
    func updateUserProfile(_ user: MessagingChatUserProfile, name: String, avatar: String) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    var isSupportChatsListPagination: Bool { false }
    
    func getChatsListForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTPServiceHelper.getClientFor(user: user, env: env)
        let conversations = try await client.conversations.list()
        let chats = conversations.compactMap({ XMTPEntitiesTransformer.convertXMTPChatToChat($0,
                                                                                             userId: user.id,
                                                                                             userWallet: user.wallet,
                                                                                             isApproved: true) })
        let blockedUsersStorage = self.blockedUsersStorage
        Task.detached {
            let notBlockedChats = chats.filter({ !blockedUsersStorage.isOtherUserBlockedInChat($0.displayInfo) })
            let topicsToSubscribeForPN = notBlockedChats.map { self.getXMTPConversationTopicFromChat($0) }
            try? await XMTPPushNotificationsHelper.subscribeForTopics(topicsToSubscribeForPN, by: client)
        }
        
        return chats
    }
    
    func getChatRequestsForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        []
    }
    
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus {
        if blockedUsersStorage.isOtherUserBlockedInChat(chat) {
            return .otherUserIsBlocked
        } else {
            return .unblocked
        }
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus {
        let isOtherUserBlocked: Bool
        do {
            let domain = try await MessagingAPIServiceHelper.getAnyDomainItem(for: chat.displayInfo.thisUserDetails.wallet)
            let notificationsPreferences = try await NetworkService().fetchUserDomainNotificationsPreferences(for: domain)
            let chatTopic = chat.displayInfo.id
            blockedUsersStorage.updatedBlockedUsersListFor(userId: chat.userId, blockedTopics: notificationsPreferences.blockedTopics)

            isOtherUserBlocked = notificationsPreferences.blockedTopics.contains(chatTopic)
        } catch {
            isOtherUserBlocked = blockedUsersStorage.isOtherUserBlockedInChat(chat.displayInfo)
        }
        
        if isOtherUserBlocked {
            return .otherUserIsBlocked
        } else {
            return .unblocked
        }
    }
    
    func setUser(in chat: MessagingChat, blocked: Bool, by user: MessagingChatUserProfile) async throws {
        switch chat.displayInfo.type {
        case .private:
            let domain = try await MessagingAPIServiceHelper.getAnyDomainItem(for: user.wallet)
            var notificationsPreferences = try await NetworkService().fetchUserDomainNotificationsPreferences(for: domain)
            let chatTopic = chat.displayInfo.id
            if blocked {
                notificationsPreferences.blockedTopics.append(chatTopic)
            } else {
                notificationsPreferences.blockedTopics.removeAll(where: { $0 == chatTopic })
            }
            try await NetworkService().updateUserDomainNotificationsPreferences(notificationsPreferences, for: domain)
            blockedUsersStorage.updatedBlockedUsersListFor(userId: chat.userId, blockedTopics: notificationsPreferences.blockedTopics)
            setSubscribed(!blocked,
                          toChat: chat,
                          by: user)
        case .group:
            throw XMTPServiceError.unsupportedAction
        }
    }
    
    func isAbleToContactAddress(_ address: String,
                                by user: MessagingChatUserProfile) async throws -> Bool {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTPServiceHelper.getClientFor(user: user, env: env)
        return try await client.canMessage(address.ethChecksumAddress())
    }
    
    func getMessagesForChat(_ chat: MessagingChat,
                            before message: MessagingChatMessage?,
                            cachedMessages: [MessagingChatMessage],
                            fetchLimit: Int,
                            isRead: Bool,
                            for user: MessagingChatUserProfile,
                            filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        
        var message = message
        var fetchLimitToUse = fetchLimit
        var beforeTimeFilter = message?.displayInfo.time
        var messagesToKeep = [MessagingChatMessage]()
        let result = messageToLoadDescriptionFrom(in: cachedMessages, before: message)
        
        switch result {
        case .noCachedMessages:
            Void()
        case .reachedFirstMessageInChat:
            messagesToKeep = cachedMessages
        case .messageToLoad(let missingMessageThreadHash):
            beforeTimeFilter = missingMessageThreadHash.beforeTimeFilter
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
                                                                               before: beforeTimeFilter,
                                                                               cachedMessages: cachedMessages,
                                                                               fetchLimit: fetchLimitToUse,
                                                                               isRead: isRead,
                                                                               filesService: filesService,
                                                                               for: user)
        if remoteMessages.count < fetchLimit {
            if !remoteMessages.isEmpty {
                remoteMessages[remoteMessages.count - 1].displayInfo.isFirstInChat = true
            } else {
                message?.displayInfo.isFirstInChat = true
            }
        }
        
        var chatMessages = [MessagingChatMessage]()
        if let message {
            chatMessages = [message]
        }
        chatMessages += messagesToKeep
        chatMessages += remoteMessages
        
        
        assignPreviousMessagesIn(messages: &chatMessages)
        
        return chatMessages
    }
    
    func isMessagesEncryptedIn(chatType: MessagingChatType) async -> Bool {
        true
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat,
                     by user: MessagingChatUserProfile,
                     filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTPServiceHelper.getClientFor(user: user, env: env)
        let conversation = try MessagingAPIServiceHelper.getXMTPConversationFromChat(chat, client: client )
        return try await sendMessage(messageType,
                                     in: conversation,
                                     chat: chat,
                                     filesService: filesService)
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType, to userInfo: MessagingChatUserDisplayInfo, by user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> (MessagingChat, MessagingChatMessage) {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTPServiceHelper.getClientFor(user: user, env: env)
        let conversation = try await client.conversations.newConversation(with: userInfo.getETHWallet())
        guard let chat = XMTPEntitiesTransformer.convertXMTPChatToChat(conversation,
                                                                       userId: user.id,
                                                                       userWallet: user.wallet,
                                                                       isApproved: true) else { throw XMTPServiceError.failedToParseChat }
        var message = try await sendMessage(messageType,
                                            in: conversation,
                                            chat: chat,
                                            filesService: filesService)
        message.displayInfo.isFirstInChat = true
        return (chat, message)
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func leaveGroupChat(_ chat: MessagingChat, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func loadRemoteContentFor(_ message: MessagingChatMessage,
                              serviceData: Data,
                              filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType {
        try await XMTPEntitiesTransformer.loadRemoteContentFrom(data: serviceData,
                                                                messageId: message.displayInfo.id,
                                                                userId: message.userId,
                                                                filesService: filesService)
    }
}

// MARK: - Private methods
private extension XMTPMessagingAPIService {
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in conversation: XMTP.Conversation,
                     chat: MessagingChat,
                     filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage {
        let senderWallet = chat.displayInfo.thisUserDetails.wallet
        let messageID: String
        switch messageType {
        case .text(let messagingChatMessageTextTypeDisplayInfo):
            messageID = try await conversation.send(text: messagingChatMessageTextTypeDisplayInfo.text)
        case .imageBase64(let messagingChatMessageImageBase64TypeDisplayInfo):
            guard let data = messagingChatMessageImageBase64TypeDisplayInfo.image?.dataToUpload else { throw XMTPServiceError.failedToPrepareImageToSend }
            messageID = try await sendImageAttachment(data: data,
                                                      in: conversation,
                                                      by: senderWallet)
        case .imageData(let displayInfo):
            messageID = try await sendImageAttachment(data: displayInfo.data,
                                                      in: conversation,
                                                      by: senderWallet)
        case .unknown, .remoteContent:
            throw XMTPServiceError.unsupportedAction
        }
        
        let newestMessages = try await conversation.messages(limit: 3, before: Date().addingTimeInterval(100)) // Get latest message
        guard let xmtpMessage = newestMessages.first(where: { $0.id == messageID }),
              let message = XMTPEntitiesTransformer.convertXMTPMessageToChatMessage(xmtpMessage,
                                                                                    cachedMessage: nil,
                                                                                    in: chat,
                                                                                    isRead: true,
                                                                                    filesService: filesService) else { throw XMTPServiceError.failedToFindSentMessage }
        
        return message
    }
    
    func setSubscribed(_ isSubscribed: Bool,
                       toChat chat: MessagingChat,
                       by user: MessagingChatUserProfile) {
        Task {
            do {
                let env = getCurrentXMTPEnvironment()
                let client = try await XMTPServiceHelper.getClientFor(user: user, env: env)
                let topic = getXMTPConversationTopicFromChat(chat)
                let topics = [topic]
                if isSubscribed {
                    try await XMTPPushNotificationsHelper.subscribeForTopics(topics, by: client)
                } else {
                    try await XMTPPushNotificationsHelper.unsubscribeFromTopics(topics, by: client)
                }
            } catch {
                Debugger.printFailure("Failed to set subscribed: \(isSubscribed) for XMTP topics")
            }
        }
    }
}

// MARK: - Get messages related
private extension XMTPMessagingAPIService {
    func messageToLoadDescriptionFrom(in cachedMessages: [MessagingChatMessage], before message: MessagingChatMessage?) -> MessageToLoadFromResult {
        guard let message,
              !cachedMessages.isEmpty else { return .noCachedMessages }
        guard let cachedMessage = cachedMessages.first,
              let beforeMessageLink = getLinkFrom(message: message),
              beforeMessageLink == cachedMessage.displayInfo.id else {
            return .messageToLoad(MessageToLoad(beforeTimeFilter: message.displayInfo.time,
                                                offset: 0,
                                                messagesToKeep: []))
        }
        
        var currentMessage = cachedMessages.first!
        var offset = 1
        var messagesToKeep: [MessagingChatMessage] = [currentMessage]
        
        for i in 1..<cachedMessages.count {
            let previousMessage = cachedMessages[i]
            guard let currentMessageLink = getLinkFrom(message: currentMessage) else { return .reachedFirstMessageInChat }
            if currentMessageLink != previousMessage.displayInfo.id {
                return .messageToLoad(MessageToLoad(beforeTimeFilter: currentMessage.displayInfo.time,
                                                    offset: offset,
                                                    messagesToKeep: messagesToKeep))
            }
            offset += 1
            currentMessage = previousMessage
            messagesToKeep.append(previousMessage)
        }
        
        return .messageToLoad(MessageToLoad(beforeTimeFilter: currentMessage.displayInfo.time,
                                            offset: offset,
                                            messagesToKeep: messagesToKeep))
    }
    enum MessageToLoadFromResult {
        case noCachedMessages
        case reachedFirstMessageInChat
        case messageToLoad(MessageToLoad)
    }
    struct MessageToLoad {
        let beforeTimeFilter: Date
        let offset: Int
        let messagesToKeep: [MessagingChatMessage]
    }
    
    func getLinkFrom(message: MessagingChatMessage) -> String? {
        let messageMetadata: XMTPEnvironmentNamespace.MessageServiceMetadata? = try? MessagingAPIServiceHelper.decodeServiceMetadata(from: message.serviceMetadata)
        return messageMetadata?.previousMessageId
    }
    
    func assignPreviousMessagesIn(messages: inout [MessagingChatMessage]) {
        guard !messages.isEmpty else { return }
        
        for i in 1..<messages.count {
            setPreviousMessageId(messages[i].displayInfo.id, to: &messages[i-1])
        }
    }
    
    func setPreviousMessageId(_ previousMessageId: String, to message: inout MessagingChatMessage) {
        guard var messageMetadata: XMTPEnvironmentNamespace.MessageServiceMetadata = try? MessagingAPIServiceHelper.decodeServiceMetadata(from: message.serviceMetadata) else { return }

        messageMetadata.previousMessageId = previousMessageId
        message.serviceMetadata = messageMetadata.jsonData()
    }
}

// MARK: - Private methods
private extension XMTPMessagingAPIService {
    func storeKeysDataFromClientIfNeeded(_ client: XMTP.Client,
                                         domain: DomainItem,
                                         env: XMTPEnvironment) throws {
        let wallet = try domain.getETHAddressThrowing()
        guard KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) == nil else { return } // Already saved
        
        let keysData = try client.privateKeyBundle.serializedData()
        KeychainXMTPKeysStorage.instance.saveKeysData(keysData,
                                                      forIdentifier: wallet,
                                                      env: env)
    }
    
    func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        try await MessagingAPIServiceHelper.getAnyDomainItem(for: wallet)
    }
    
    func getCurrentXMTPEnvironment() -> XMTPEnvironment {
        XMTPServiceHelper.getCurrentXMTPEnvironment()
    }
    
    func sendImageAttachment(data: Data,
                             in conversation: Conversation,
                             by wallet: HexAddress) async throws -> String {
        try await sendAttachment(data: data,
                                 filename: "\(UUID().uuidString).png",
                                 mimeType: "image/png",
                                 in: conversation,
                                 by: wallet)
    }
    
    func sendAttachment(data: Data,
                        filename: String,
                        mimeType: String,
                        in conversation: Conversation,
                        by wallet: HexAddress) async throws -> String {
        let attachment = Attachment(filename: filename,
                                    mimeType: mimeType,
                                    data: data)
        let encryptedAttachment = try RemoteAttachment.encodeEncrypted(content: attachment,
                                                                       codec: AttachmentCodec())
        let url = try await uploadDataToWeb3Storage(encryptedAttachment.payload, by: wallet)
        let remoteAttachment = try RemoteAttachment(url: url,
                                                    encryptedEncodedContent: encryptedAttachment)
        return try await conversation.send(content: remoteAttachment,
                                           options: .init(contentType: ContentTypeRemoteAttachment))
    }
    
    func uploadDataToWeb3Storage(_ data: Data,
                                 by wallet: HexAddress) async throws -> String {
        struct Web3StorageResponse: Codable {
            let carCid: String
            let cid: String
        }
        
        let token = await getWeb3StorageKey(for: wallet)
        let url = URL(string: "https://api.web3.storage/upload")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("XMTP", forHTTPHeaderField: "X-NAME")
        request.httpMethod = "POST"
        
        let responseData = try await URLSession.shared.upload(for: request, from: data).0
        let response = try Web3StorageResponse.objectFromDataThrowing(responseData)
        
        return "https://\(response.cid).ipfs.w3s.link"
    }
    
    func getXMTPConversationTopicFromChat(_ chat: MessagingChat) -> String {
        chat.displayInfo.id // XMTP Chat's topic = chat's id
    }
    
    func getWeb3StorageKey(for wallet: HexAddress) async -> String {
        if let cachedKey = await cachedDataHolder.getKeyFor(wallet: wallet) {
            return cachedKey
        } else if let domain = try? await MessagingAPIServiceHelper.getAnyDomainItem(for: wallet),
                  let profile = try? await NetworkService().fetchUserDomainProfile(for: domain, fields: [.profile]),
                  let storage = profile.storage,
                  storage.type == .web3 {
            let key = storage.apiKey
            await cachedDataHolder.setKey(key, for: wallet)
            return key
        }
        
        if User.instance.getSettings().isTestnetUsed {
            return Web3Storage.StagingAPIKey
        } else {
            return Web3Storage.ProductionAPIKey
        }
    }
}

// MARK: - Private methods
private extension XMTPMessagingAPIService {
    actor CachedDataHolder {
        var walletsToStorageKeys: [HexAddress : String] = [:]
        
        func getKeyFor(wallet: HexAddress) -> String? {
            walletsToStorageKeys[wallet]
        }
        
        func setKey(_ key: String, for wallet: HexAddress) {
            walletsToStorageKeys[wallet] = key
        }
    }
}

// MARK: - Open methods
extension XMTPMessagingAPIService {
    enum XMTPServiceError: String, Error {
        case unsupportedAction
        case userNotCreatedYet
        
        case failedToParseChat
        case failedToPrepareImageToSend
        case failedToFindSentMessage

        public var errorDescription: String? { rawValue }
    }
}

extension DomainItem: SigningKey {
    var address: String { getETHAddress() ?? "" }
    
    func sign(_ data: Data) async throws -> XMTP.Signature {
        try await sign(message: HexAddress.hexPrefix + data.dataToHexString())
    }
    
    func sign(message: String) async throws -> XMTP.Signature {
        guard let udWalletAddress = ownerWallet,
              let udWallet = appContext.udWalletsService.find(by: udWalletAddress) else {
            throw UDWallet.Error.failedToFindWallet }
        let newMess = "0x" + Data(message.utf8).toHexString()
        let sign = try await udWallet.getPersonalSignature(messageString: newMess, shouldTryToConverToReadable: false)
        var bytes = sign.hexToBytes()
        bytes[bytes.count - 1] = 1 - bytes[bytes.count - 1] % 2
        return .init(bytes: Data(bytes[0...63]), recovery: Int(bytes[64]))
    }
}

final class DefaultXMTPMessagingAPIServiceDataProvider: XMTPMessagingAPIServiceDataProvider {
    func getPreviousMessagesForChat(_ chat: MessagingChat,
                                    before: Date?,
                                    cachedMessages: [MessagingChatMessage],
                                    fetchLimit: Int,
                                    isRead: Bool,
                                    filesService: MessagingFilesServiceProtocol,
                                    for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage] {
        
        let env = XMTPServiceHelper.getCurrentXMTPEnvironment()
        let client = try await XMTPServiceHelper.getClientFor(user: user, env: env)
        let conversation = try MessagingAPIServiceHelper.getXMTPConversationFromChat(chat, client: client)
        let start = Date()
        let messages = try await conversation.messages(limit: fetchLimit, before: before)
        Debugger.printTimeSensitiveInfo(topic: .Messaging, "load \(messages.count) messages. fetchLimit: \(fetchLimit). before: \(before)", startDate: start, timeout: 1)
        
        let chatMessages = messages.compactMap({ xmtpMessage in
            XMTPEntitiesTransformer.convertXMTPMessageToChatMessage(xmtpMessage,
                                                                    cachedMessage: cachedMessages.first(where: { $0.displayInfo.id == xmtpMessage.id }),
                                                                    in: chat,
                                                                    isRead: isRead,
                                                                    filesService: filesService)
        })
        
        return chatMessages
    }
}
