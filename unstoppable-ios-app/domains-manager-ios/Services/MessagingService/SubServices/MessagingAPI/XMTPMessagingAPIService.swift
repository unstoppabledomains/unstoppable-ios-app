//
//  XMTPMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import XMTP

final class XMTPMessagingAPIService {
    
    private let messagingHelper = MessagingAPIServiceHelper()
    private let xmtpHelper = XMTPServiceHelper()
    private let blockedUsersStorage = XMTPBlockedUsersStorage.shared
    let capabilities = MessagingServiceCapabilities(canContactWithoutProfile: false,
                                                    canBlockUsers: true,
                                                    isSupportChatsListPagination: false)
    init() {
        Client.register(codec: AttachmentCodec())
        Client.register(codec: RemoteAttachmentCodec())
    }
    
}

// MARK: - MessagingAPIServiceProtocol
extension XMTPMessagingAPIService: MessagingAPIServiceProtocol {
    func getUserFor(domain: DomainItem) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        
        //TODO: - Check for .canMessage
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
                                                                            isSecure: true)))

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
        let client = try await xmtpHelper.getClientFor(user: user, env: env)
        let conversations = try await client.conversations.list()
        Task.detached {
            try? await XMTPPush.shared.subscribe(topics: conversations.map(\.topic))
        }
        
        return conversations.compactMap({ XMTPEntitiesTransformer.convertXMTPChatToChat($0,
                                                                                        userId: user.id,
                                                                                        userWallet: user.wallet,
                                                                                        isApproved: true) })
    }
    
    func getChatRequestsForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        []
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus {
        let isOtherUserBlocked = blockedUsersStorage.isOtherUserBlockedInChat(chat)
        if isOtherUserBlocked {
            return .otherUserIsBlocked
        } else {
            return .unblocked
        }
    }
    
    func setUser(in chat: MessagingChat, blocked: Bool, by user: MessagingChatUserProfile) async throws {
        switch chat.displayInfo.type {
        case .private(let details):
            let userId = user.displayInfo.wallet
            let otherUserId = details.otherUser.wallet
            let blockedUserDescription = XMTPBlockedUserDescription(userId: userId,
                                                                    blockedUserId: otherUserId)
            if blocked {
                blockedUsersStorage.addBlockedUser(blockedUserDescription)
            } else {
                blockedUsersStorage.removeBlockedUser(blockedUserDescription)
            }
        case .group:
            throw XMTPServiceError.unsupportedAction
        }
    }
    
    func isAbleToContactAddress(_ address: String,
                                by user: MessagingChatUserProfile) async throws -> Bool {
        let env = getCurrentXMTPEnvironment()
        let client = try await xmtpHelper.getClientFor(user: user, env: env)
        return try await client.canMessage(address.ethChecksumAddress())
    }
    
    func getMessagesForChat(_ chat: MessagingChat,
                            before message: MessagingChatMessage?,
                            cachedMessages: [MessagingChatMessage],
                            fetchLimit: Int,
                            isRead: Bool,
                            for user: MessagingChatUserProfile,
                            filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        let env = getCurrentXMTPEnvironment()
        let client = try await xmtpHelper.getClientFor(user: user, env: env)
        let conversation = try getXMTPConversationFromChat(chat, client: client )
        let messages = try await conversation.messages(limit: fetchLimit, before: message?.displayInfo.time)
        
        var chatMessages = messages.compactMap({ xmtpMessage in
            XMTPEntitiesTransformer.convertXMTPMessageToChatMessage(xmtpMessage,
                                                                    cachedMessage: cachedMessages.first(where: { $0.displayInfo.id == xmtpMessage.id }),
                                                                    in: chat,
                                                                    isRead: isRead,
                                                                    filesService: filesService)
        })
        if chatMessages.count < fetchLimit,
           !chatMessages.isEmpty {
            chatMessages[chatMessages.count - 1].displayInfo.isFirstInChat = true 
        }
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
        let client = try await xmtpHelper.getClientFor(user: user, env: env)
        let conversation = try getXMTPConversationFromChat(chat, client: client )
        return try await sendMessage(messageType,
                                     in: conversation,
                                     chat: chat,
                                     filesService: filesService)
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType, to userInfo: MessagingChatUserDisplayInfo, by user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> (MessagingChat, MessagingChatMessage) {
        let env = getCurrentXMTPEnvironment()
        let client = try await xmtpHelper.getClientFor(user: user, env: env)
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
    func getXMTPConversationFromChat(_ chat: MessagingChat,
                                     client: XMTP.Client) throws -> XMTP.Conversation {
        let metadata: XMTPEnvironmentNamespace.ChatServiceMetadata = try messagingHelper.decodeServiceMetadata(from: chat.serviceMetadata)
        return metadata.encodedContainer.decode(with: client)
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in conversation: XMTP.Conversation,
                     chat: MessagingChat,
                     filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage {
        let messageID: String
        switch messageType {
        case .text(let messagingChatMessageTextTypeDisplayInfo):
            messageID = try await conversation.send(text: messagingChatMessageTextTypeDisplayInfo.text)
        case .imageBase64(let messagingChatMessageImageBase64TypeDisplayInfo):
            guard let data = messagingChatMessageImageBase64TypeDisplayInfo.image?.dataToUpload else { throw XMTPServiceError.failedToPrepareImageToSend }
            messageID = try await sendImageAttachment(data: data,
                                                      in: conversation)
        case .imageData(let displayInfo):
            messageID = try await sendImageAttachment(data: displayInfo.data,
                                                      in: conversation)
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
        try await messagingHelper.getAnyDomainItem(for: wallet)
    }
    
    func getCurrentXMTPEnvironment() -> XMTPEnvironment {
        xmtpHelper.getCurrentXMTPEnvironment()
    }
    
    func sendImageAttachment(data: Data,
                             in conversation: Conversation) async throws -> String {
        try await sendAttachment(data: data,
                                 filename: "\(UUID().uuidString).png",
                                 mimeType: "image/png",
                                 in: conversation)
    }
    
    func sendAttachment(data: Data,
                        filename: String,
                        mimeType: String,
                        in conversation: Conversation) async throws -> String {
        let attachment = Attachment(filename: filename,
                                    mimeType: mimeType,
                                    data: data)
        let encryptedAttachment = try RemoteAttachment.encodeEncrypted(content: attachment,
                                                                       codec: AttachmentCodec())
        let url = try await uploadDataToWeb3Storage(encryptedAttachment.payload)
        let remoteAttachment = try RemoteAttachment(url: url,
                                                    encryptedEncodedContent: encryptedAttachment)
        return try await conversation.send(content: remoteAttachment,
                                           options: .init(contentType: ContentTypeRemoteAttachment))
    }
    
    func uploadDataToWeb3Storage(_ data: Data) async throws -> String {
        struct Web3StorageResponse: Codable {
            let carCid: String
            let cid: String
        }
        
        let token: String
        if User.instance.getSettings().isTestnetUsed {
            token = Web3Storage.StagingAPIKey
        } else {
            token = Web3Storage.ProductionAPIKey
        }
        
        let url = URL(string: "https://api.web3.storage/upload")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("XMTP", forHTTPHeaderField: "X-NAME")
        request.httpMethod = "POST"
        
        let responseData = try await URLSession.shared.upload(for: request, from: data).0
        let response = try Web3StorageResponse.objectFromDataThrowing(responseData)
        
        return "https://\(response.cid).ipfs.w3s.link"
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
