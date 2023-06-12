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
    
    private var walletToPushUserCache: [HexAddress : PushUser] = [:]
    
}

// MARK: - MessagingAPIServiceProtocol
extension PushMessagingAPIService: MessagingAPIServiceProtocol {
    // Chats
    func getUserFor(wallet: HexAddress) async throws -> MessagingChatUserDisplayInfo {
        let pushUser = try await getPushUserFor(wallet: wallet)
        return PushEntitiesTransformer.convertPushUserToChatUser(pushUser)
    }
    
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserDisplayInfo {
        let wallet = try await domain.getAddress()
        let env = getCurrentPushEnvironment()
        let pushUser = try await PushUser.create(options: .init(env: env,
                                                                signer: domain,
                                                                version: .PGP_V3,
                                                                progressHook: nil))
        walletToPushUserCache[wallet] = pushUser
        let chatUser = PushEntitiesTransformer.convertPushUserToChatUser(pushUser)
        
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: pushUser.encryptedPrivateKey, signer: domain)
        KeychainPGPKeysStorage.instance.savePGPKey(pgpPrivateKey,
                                                   forIdentifier: wallet)
        
        return chatUser
    }
    
    func getChatsListForWallet(_ wallet: HexAddress,
                               page: Int,
                               limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await pushRESTService.getChats(for: wallet,
                                                           page: page,
                                                           limit: limit,
                                                           isRequests: false)
        
        let chats = pushChats.compactMap({ PushEntitiesTransformer.convertPushChatToChat($0,
                                                                                         userWallet: wallet,
                                                                                         isApproved: true) })
        return chats
    }
    
    func getChatRequestsForWallet(_ wallet: HexAddress,
                                  page: Int,
                                  limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await pushRESTService.getChats(for: wallet,
                                                           page: page,
                                                           limit: limit,
                                                           isRequests: true)
        let chats = pushChats.compactMap({ PushEntitiesTransformer.convertPushChatToChat($0,
                                                                                         userWallet: wallet,
                                                                                         isApproved: false) })
        return chats
    }
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            options: MessagingAPIServiceLoadMessagesOptions,
                            fetchLimit: Int) async throws -> [MessagingChatMessage] {
        switch options {
        case .default:
            let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
            guard let threadHash = chatMetadata.threadHash else {
                return [] // NULL threadHash means there's no messages in the chat yet
            }
            return try await getPreviousMessagesForChat(chat, threadHash: threadHash, fetchLimit: fetchLimit)
        case .before(let message):
            let messageMetadata: PushEnvironment.MessageServiceMetadata = try decodeServiceMetadata(from: message.serviceMetadata)
            guard let threadHash = messageMetadata.link else {
                return []
            }
            return try await getPreviousMessagesForChat(chat, threadHash: threadHash, fetchLimit: fetchLimit)
        case .after(let message):
            let chatMetadata: PushEnvironment.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
            guard var threadHash = chatMetadata.threadHash else {
                return []
            }
            
            var messages = [MessagingChatMessage]()
            
            while true {
                let chunkMessages = try await getPreviousMessagesForChat(chat, threadHash: threadHash, fetchLimit: fetchLimit)
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
                                            fetchLimit: Int) async throws -> [MessagingChatMessage] {
        let wallet = chat.displayInfo.thisUserDetails.wallet
        let pgpPrivateKey = try await getPGPPrivateKeyFor(wallet: wallet)
        let env = getCurrentPushEnvironment()
        let pushMessages = try await Push.PushChat.History(threadHash: threadHash,
                                                           limit: fetchLimit,
                                                           pgpPrivateKey: "",
                                                           toDecrypt: false,
                                                           env: env)
        
        let messages = pushMessages.compactMap({ PushEntitiesTransformer.convertPushMessageToChatMessage($0, in: chat, pgpKey: pgpPrivateKey) })
        return messages
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat) async throws -> MessagingChatMessage {
        let env = getCurrentPushEnvironment()
        let pushMessageContent = getPushMessageContentFrom(displayType: messageType)
        let pushMessageType = getPushMessageTypeFrom(displayType: messageType)
        let sender = chat.displayInfo.thisUserDetails
        let pgpPrivateKey = try await getPGPPrivateKeyFor(wallet: sender.wallet)

        switch chat.displayInfo.type {
        case .private(let otherUserDetails):
            let receiver = otherUserDetails.otherUser
            let sendOptions = Push.PushChat.SendOptions(messageContent: pushMessageContent,
                                                        messageType: pushMessageType.rawValue,
                                                        receiverAddress: receiver.wallet,
                                                        account: sender.wallet,
                                                        pgpPrivateKey: pgpPrivateKey,
                                                        env: env)
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
                                                                                            pgpKey: pgpPrivateKey) else { throw PushMessagingAPIServiceError.failedToConvertPushMessage }
            
            return chatMessage
        case .group(let groupDetails):
            throw PushMessagingAPIServiceError.sendMessageInGroupChatNotSupported  // <GROUP_CHAT> Group chats not supported for now
        }
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool) async throws {
        guard approved else { throw PushMessagingAPIServiceError.declineRequestNotSupported }
        guard case .private(let otherUserDetails) = chat.displayInfo.type else { throw PushMessagingAPIServiceError.sendMessageInGroupChatNotSupported }
        
        let env = getCurrentPushEnvironment()
        let sender = chat.displayInfo.thisUserDetails
        let pgpPrivateKey = try await getPGPPrivateKeyFor(wallet: sender.wallet)

        let approveOptions = Push.PushChat.ApproveOptions(fromAddress: sender.wallet ,
                                                          toAddress: otherUserDetails.otherUser.wallet,
                                                          privateKey: pgpPrivateKey,
                                                          env: env)
        _ = try await Push.PushChat.approve(approveOptions)
    }
    
    // Channels
    func getSubscribedChannelsFor(wallet: HexAddress) async throws -> [MessagingNewsChannel] {
        let subscribedChannelsIds = try await pushRESTService.getSubscribedChannelsIds(for: wallet)
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
        
        return channels.compactMap({ $0 }).map({ PushEntitiesTransformer.convertPushChannelToMessagingChannel($0) })
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
    func getPushUserFor(wallet: HexAddress) async throws -> PushUser {
        if let pushUser = walletToPushUserCache[wallet] {
            return pushUser
        }
        let env = getCurrentPushEnvironment()
        guard let pushUser = try await PushUser.get(account: wallet, env: env) else {
            throw PushMessagingAPIServiceError.failedToGetPushUser
        }
        walletToPushUserCache[wallet] = pushUser
        return pushUser
    }
    
    func getPGPPrivateKeyFor(wallet: HexAddress) async throws -> String {
        if let key = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet) {
            return key
        }
        let user = try await getPushUserFor(wallet: wallet)
        let domain = try await getReverseResolutionDomainItem(for: wallet)
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: user.encryptedPrivateKey, signer: domain)
        KeychainPGPKeysStorage.instance.savePGPKey(pgpPrivateKey, forIdentifier: wallet)
        return pgpPrivateKey
    }
    
    func getReverseResolutionDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        guard let domainName = await appContext.dataAggregatorService.getReverseResolutionDomain(for: wallet) else {
            throw PushMessagingAPIServiceError.noRRDomainForWallet
        }
        
        return try await appContext.dataAggregatorService.getDomainWith(name: domainName)
    }
    
    func getCurrentPushEnvironment() -> Push.ENV {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .DEV : .PROD
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
   
    func getPushMessageContentFrom(displayType: MessagingChatMessageDisplayType) -> String {
        switch displayType {
        case .text(let details):
            return details.text
        }
    }
    
    func getPushMessageTypeFrom(displayType: MessagingChatMessageDisplayType) -> PushMessageType {
        switch displayType {
        case .text:
            return .text
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
        case noRRDomainForWallet
        case noOwnerWalletInDomain
        case failedToGetPushUser
        case incorrectDataState
        
        case failedToDecodeServiceData
        case failedToConvertPushMessage
        case sendMessageInGroupChatNotSupported
        case declineRequestNotSupported
    }
}

extension DomainItem: Push.Signer {
    func getEip191Signature(message: String) async throws -> String {
        try await self.personalSign(message: message)
    }
    
    func getAddress() async throws -> String {
        guard let ownerWallet else { throw PushMessagingAPIService.PushMessagingAPIServiceError.noOwnerWalletInDomain }
        
        return ownerWallet
    }
}
