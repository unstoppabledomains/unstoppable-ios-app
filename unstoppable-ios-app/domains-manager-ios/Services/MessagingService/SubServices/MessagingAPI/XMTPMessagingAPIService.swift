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
        .unblocked
    }
    
    func setUser(in chat: MessagingChat, blocked: Bool, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
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
        
        return messages.compactMap({ XMTPEntitiesTransformer.convertXMTPMessageToChatMessage($0,
                                                                                             in: chat,
                                                                                             isRead: isRead,
                                                                                             filesService: filesService) })
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
        let conversation = try await client.conversations.newConversation(with: userInfo.wallet)
        guard let chat = XMTPEntitiesTransformer.convertXMTPChatToChat(conversation,
                                                                       userId: user.id,
                                                                       userWallet: user.wallet,
                                                                       isApproved: true) else { throw XMTPServiceError.failedToParseChat }
        let message = try await sendMessage(messageType,
                                            in: conversation,
                                            chat: chat,
                                            filesService: filesService)
        return (chat, message)
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func leaveGroupChat(_ chat: MessagingChat, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
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
        case .unknown:
            throw XMTPServiceError.unsupportedAction
        }
        
        let newestMessages = try await conversation.messages(limit: 3, before: Date().addingTimeInterval(100)) // Get latest message
        guard let xmtpMessage = newestMessages.first(where: { $0.id == messageID }),
              let message = XMTPEntitiesTransformer.convertXMTPMessageToChatMessage(xmtpMessage,
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
                                                      forIdentifier: wallet, env: env)
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
        return try await conversation.send(content: attachment,
                                           options: .init(contentType: ContentTypeAttachment))
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
    var address: String { ownerWallet ?? "" }
    
    func sign(_ data: Data) async throws -> XMTP.Signature {
        .init()
    }
    
    func sign(message: String) async throws -> XMTP.Signature {
        .init()
    }
}
