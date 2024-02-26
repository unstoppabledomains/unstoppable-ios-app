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
    private let approvedUsersStorage = XMTPApprovedTopicsStorage.shared
    private let cachedDataHolder = CachedDataHolder()
    let capabilities = MessagingServiceCapabilities(canContactWithoutProfile: false,
                                                    canBlockUsers: true,
                                                    isSupportChatsListPagination: false,
                                                    isRequiredToReloadLastMessage: true)
    let dataProvider: XMTPMessagingAPIServiceDataProvider
    
    init(dataProvider: XMTPMessagingAPIServiceDataProvider = DefaultXMTPMessagingAPIServiceDataProvider()) {
        self.dataProvider = dataProvider
    }
    
}
 
// MARK: - MessagingAPIServiceProtocol
extension XMTPMessagingAPIService: MessagingAPIServiceProtocol {
    var serviceIdentifier: MessagingServiceIdentifier { .xmtp }

    func getUserFor(wallet: WalletEntity) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        
        let walletAddress = wallet.ethFullAddress
        guard KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: walletAddress, env: env) != nil else {
            throw XMTPServiceError.userNotCreatedYet
        }
        
        return try await createUser(for: wallet) /// In XMTP same function responsible for either get or create profile
    }
    
    func createUser(for wallet: WalletEntity) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        let account = WalletXMTPSigningKey(walletEntity: wallet)
        let client = try await XMTP.Client.create(account: account,
                                                  options: .init(api: .init(env: env,
                                                                            isSecure: true,
                                                                            appVersion: XMTPServiceSharedHelper.getXMTPVersion())))

        try storeKeysDataFromClientIfNeeded(client, wallet: wallet, env: env)
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
        try await migrateXMTPConsentsFromUDIfNeeded(for: user, client: client, using: conversations)
        
        let approvedAddressesList = XMTPServiceHelper.getListOfApprovedAddressesForUser(user)
        let chats = conversations.compactMap({ conversation in
            XMTPEntitiesTransformer.convertXMTPChatToChat(conversation,
                                                          userId: user.id,
                                                          userWallet: user.wallet,
                                                          isApproved: approvedAddressesList.contains(conversation.peerAddress))
        })
        
        
        Task.detached {
            let topicsToSubscribeForPN = chats.map { self.getXMTPConversationTopicFromChat($0) }
            try? await XMTPPushNotificationsHelper.subscribeForTopics(topicsToSubscribeForPN, by: client)
        }
        
        return chats
    }
    
    func migrateXMTPConsentsFromUDIfNeeded(for user: MessagingChatUserProfile,
                                            client: XMTP.Client,
                                            using conversations: [Conversation]) async throws {

        if !UserDefaults.didMigrateXMTPConsentsListFromUD,
           let domain = try? await MessagingAPIServiceHelper.getAnyDomainItem(for: user.wallet),
           let notificationsPreferences = try? await NetworkService().fetchUserDomainNotificationsPreferences(for: domain) {
            // Approved contacts
            let approvedAddresses = conversations
                .filter { notificationsPreferences.acceptedTopics.contains($0.topic) }
                .map { $0.peerAddress }
            if !approvedAddresses.isEmpty {
                try await client.contacts.allow(addresses: approvedAddresses)
            }
            
            // Blocked contacts
            let blockedAddresses = conversations
                .filter { notificationsPreferences.blockedTopics.contains($0.topic) }
                .map { $0.peerAddress }
            if !blockedAddresses.isEmpty {
                try await client.contacts.deny(addresses: blockedAddresses)
            }
            
            try await XMTPPushNotificationsHelper.unsubscribeFromTopics(notificationsPreferences.acceptedTopics + notificationsPreferences.blockedTopics,
                                                                        by: client)
            
            // Migration finished
            UserDefaults.didMigrateXMTPConsentsListFromUD = true
        }
        let consentList = try await client.contacts.refreshConsentList()
        updateLocalStorageWith(consentList: consentList, for: user)
    }
    
    func getChatRequestsForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        []
    }
    
    func getCommunitiesListForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingChat] { [] }
    
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus {
        if blockedUsersStorage.isOtherUserBlockedInChat(chat) {
            return .otherUserIsBlocked
        } else {
            return .unblocked
        }
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus {
        let isOtherUserBlocked: Bool = blockedUsersStorage.isOtherUserBlockedInChat(chat.displayInfo)
        
        if isOtherUserBlocked {
            return .otherUserIsBlocked
        } else {
            return .unblocked
        }
    }
    
    func setUser(in chat: MessagingChat, blocked: Bool, by user: MessagingChatUserProfile) async throws {
        switch chat.displayInfo.type {
        case .private:
            try await setChats(chats: [chat], blocked: blocked, by: user)
        case .group, .community:
            throw XMTPServiceError.unsupportedAction
        }
    }
    
    func setUser(_ otherUser: MessagingChatUserDisplayInfo,
                 in groupChat: MessagingChat,
                 blocked: Bool,
                 by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func block(chats: [MessagingChat],
               by user: MessagingChatUserProfile) async throws {
        try await setChats(chats: chats, blocked: true, by: user)
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
        if remoteMessages.count < fetchLimitToUse {
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
                                     client: client,
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
       
        try? await self.makeChatRequest(chat, approved: true, by: user)
        var message = try await sendMessage(messageType,
                                            in: conversation,
                                            client: client,
                                            chat: chat,
                                            filesService: filesService)
        message.displayInfo.isFirstInChat = true
        return (chat, message)
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool, by user: MessagingChatUserProfile) async throws {
        try await setChats(chats: [chat], blocked: false, by: user)
    }
    
    func leaveGroupChat(_ chat: MessagingChat, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func loadRemoteContentFor(_ message: MessagingChatMessage,
                              user: MessagingChatUserProfile,
                              serviceData: Data,
                              filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTPServiceHelper.getClientFor(user: user, env: env)
        
        return try await XMTPEntitiesTransformer.loadRemoteContentFrom(data: serviceData,
                                                                       messageId: message.displayInfo.id,
                                                                       userId: message.userId,
                                                                       client: client,
                                                                       filesService: filesService)
    }
    
    func joinCommunityChat(_ communityChat: MessagingChat,
                           by user: MessagingChatUserProfile) async throws -> MessagingChat {
        throw XMTPServiceError.unsupportedAction
    }
    
    func leaveCommunityChat(_ communityChat: MessagingChat,
                            by user: MessagingChatUserProfile) async throws -> MessagingChat {
        throw XMTPServiceError.unsupportedAction
    }
}

// MARK: - Private methods
private extension XMTPMessagingAPIService {
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in conversation: XMTP.Conversation,
                     client: XMTP.Client,
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
                                                      client: client,
                                                      by: senderWallet)
        case .imageData(let displayInfo):
            messageID = try await sendImageAttachment(data: displayInfo.data,
                                                      in: conversation,
                                                      client: client,
                                                      by: senderWallet)
        case .unknown, .remoteContent, .reaction, .reply:
            throw XMTPServiceError.unsupportedAction
        }
        
        let newestMessages = try await conversation.messages(limit: 3, before: Date().addingTimeInterval(100)) // Get latest message
        guard let xmtpMessage = newestMessages.first(where: { $0.id == messageID }),
              let message = await XMTPEntitiesTransformer.convertXMTPMessageToChatMessage(xmtpMessage,
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
    
    func setChats(chats: [MessagingChat],
                  blocked: Bool,
                  by user: MessagingChatUserProfile) async throws {
        guard !chats.isEmpty else { return }
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTPServiceHelper.getClientFor(user: user,
                                                              env: env)
        let address: [String] = chats.compactMap {
            switch $0.displayInfo.type {
            case .private(let otherUser):
                return otherUser.otherUser.wallet
            case .group, .community:
                return nil
            }
        }
        
        if blocked {
            try await client.contacts.deny(addresses: address)
        } else {
            try await client.contacts.allow(addresses: address)
        }
        
        let consentList = try await client.contacts.refreshConsentList()
        updateLocalStorageWith(consentList: consentList, for: user)
    }
    
    func updateLocalStorageWith(consentList: ConsentList,
                                for user: MessagingChatUserProfile) {
        let entries = consentList.entries.map { $0.value }
        var acceptedAddress = [String]()
        var blockedAddress = [String]()
        
        for entry in entries {
            let status = entry.consentType
            let address = entry.value
            
            switch status {
            case .allowed:
                acceptedAddress.append(address)
            case .denied:
                blockedAddress.append(address)
            case .unknown:
                continue
            }
        }
        approvedUsersStorage.updatedApprovedUsersListFor(userId: user.id,
                                                         approvedAddresses: acceptedAddress)
        blockedUsersStorage.updatedBlockedUsersListFor(userId: user.id,
                                                       blockedTopics: blockedAddress)
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
                                         wallet: WalletEntity,
                                         env: XMTPEnvironment) throws {
        let wallet = wallet.ethFullAddress
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
                             client: XMTP.Client,
                             by wallet: HexAddress) async throws -> String {
        try await sendAttachment(data: data,
                                 filename: "\(UUID().uuidString).png",
                                 mimeType: "image/png",
                                 in: conversation,
                                 client: client,
                                 by: wallet)
    }
    
    func sendAttachment(data: Data,
                        filename: String,
                        mimeType: String,
                        in conversation: Conversation,
                        client: XMTP.Client,
                        by wallet: HexAddress) async throws -> String {
        let attachment = Attachment(filename: filename,
                                    mimeType: mimeType,
                                    data: data)
        let encryptedAttachment = try RemoteAttachment.encodeEncrypted(content: attachment,
                                                                       codec: AttachmentCodec(),
                                                                       with: client)
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

private struct WalletXMTPSigningKey {
    let address: String
    let udWallet: UDWallet
    
    init(walletEntity: WalletEntity) {
        self.address = walletEntity.ethFullAddress
        self.udWallet = walletEntity.udWallet
    }
}

extension WalletXMTPSigningKey: SigningKey {
    func sign(_ data: Data) async throws -> XMTP.Signature {
        try await sign(message: HexAddress.hexPrefix + data.dataToHexString())
    }
    
    func sign(message: String) async throws -> XMTP.Signature {
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
        Debugger.printTimeSensitiveInfo(topic: .Messaging, "load \(messages.count) messages. fetchLimit: \(fetchLimit). before: \(String(describing: before))", startDate: start, timeout: 1)
        
        var chatMessages = [MessagingChatMessage]()
        for xmtpMessage in messages {
            if let chatMessage = await XMTPEntitiesTransformer.convertXMTPMessageToChatMessage(xmtpMessage,
                                                                                               cachedMessage: cachedMessages.first(where: { $0.displayInfo.id == xmtpMessage.id }),
                                                                                               in: chat,
                                                                                               isRead: isRead,
                                                                                               filesService: filesService) {
                chatMessages.append(chatMessage)
            }
        }
        
        return chatMessages
    }
}
