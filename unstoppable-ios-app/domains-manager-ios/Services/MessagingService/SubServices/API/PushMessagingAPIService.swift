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
    
    private var walletToPushUserCache: [HexAddress : Push.User] = [:]
    
}

// MARK: - MessagingAPIServiceProtocol
extension PushMessagingAPIService: MessagingAPIServiceProtocol {
    func getUserFor(wallet: HexAddress) async throws -> MessagingChatUserDisplayInfo {
        let pushUser = try await getPushUserFor(wallet: wallet)
        return convertPushUserToChatUser(pushUser)
    }
    
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserDisplayInfo {
        let wallet = try await domain.getAddress()
        let env = getCurrentPushEnvironment()
        let pushUser = try await Push.User.create(options: .init(env: env,
                                                                 signer: domain,
                                                                 version: .PGP_V3,
                                                                 progressHook: nil))
        walletToPushUserCache[wallet] = pushUser
        let chatUser = convertPushUserToChatUser(pushUser)
        return chatUser
    }
    
    func getChatsListForWallet(_ wallet: HexAddress,
                               page: Int,
                               limit: Int) async throws -> [MessagingChat] {
//        let user = try await getPushUserFor(wallet: wallet)
//        let domain = try await getReverseResolutionDomainItem(for: wallet)
//        let pgpPrivateKey = try await Push.User.DecryptPGPKey(encryptedPrivateKey: user.encryptedPrivateKey, signer: domain)
//        let env = getCurrentPushEnvironment()
//        let pushChats = try await Push.Chats.getChats(options: .init(account: wallet,
//                                                                     pgpPrivateKey: pgpPrivateKey,
//                                                                     toDecrypt: true,
//                                                                     page: page,
//                                                                     limit: limit,
//                                                                     env: env))
        // TODO: - Convert
        let pushChats = try await pushRESTService.getChats(for: wallet,
                                                       page: page,
                                                       limit: limit,
                                                       isRequests: false)
        return []
//        let channelTypes = pushChats.map({ convertPushChatToChannelType($0) })
//        return channelTypes
    }
    
    func getChatRequestsForWallet(_ wallet: HexAddress,
                                  page: Int,
                                  limit: Int) async throws -> [MessagingChat] {
        // TODO: - Convert
        let pushChats = try await pushRESTService.getChats(for: wallet,
                                                           page: page,
                                                       limit: limit,
                                                       isRequests: true)
        return []
        //        let channelTypes = pushChats.map({ convertPushChatToChannelType($0) })
        //        return channelTypes
    }
    
    func getMessagesForChat(_ chat: MessagingChat,
                            fetchLimit: Int) async throws -> [MessagingChatMessage] {
        let chatMetadata: ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
        guard let threadHash = chatMetadata.threadHash else {
            return [] // NULL threadHash means there's no messages in the chat yet
        }
        
        let wallet = chat.displayInfo.thisUserDetails.wallet
        let user = try await getPushUserFor(wallet: wallet)
        let domain = try await getReverseResolutionDomainItem(for: wallet)
        let pgpPrivateKey = try await Push.User.DecryptPGPKey(encryptedPrivateKey: user.encryptedPrivateKey, signer: domain)
        let env = getCurrentPushEnvironment()
        let messages = try await Push.Chats.History(threadHash: threadHash,
                                                    limit: fetchLimit,
                                                    pgpPrivateKey: pgpPrivateKey,
                                                    env: env)
        
        // TODO: - Convert
        return []
//        let threadHash = channel.channel.threadHash
//        let pushMessages = try await pushService.getChatMessages(threadHash: threadHash, fetchLimit: fetchLimit)
//        let messageTypes = pushMessages.compactMap({ convertPushChatMessageToMessageType($0) })
//        return messageTypes
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat) async throws {
        // TODO: - Use Push SDK when ready
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool) async throws {
        // TODO: - Use Push SDK when ready
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    func getPushUserFor(wallet: HexAddress) async throws -> Push.User {
        if let pushUser = walletToPushUserCache[wallet] {
            return pushUser
        }
        let env = getCurrentPushEnvironment()
        guard let pushUser = try await Push.User.get(account: wallet, env: env) else {
            throw PushMessagingAPIServiceError.failedToGetPushUser
        }
        return pushUser
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
    
    func convertPushUserToChatUser(_ pushUser: Push.User) -> MessagingChatUserDisplayInfo {
        MessagingChatUserDisplayInfo(wallet: pushUser.wallets,
                                     domain: nil)
    }
    
//    func convertPushChatToChannelType(_ pushChat: PushChat) -> ChatChannelType {
//        let channel = DomainChatChannel(id: pushChat.chatId,
//                                        avatarURL: URL(string: pushChat.profilePicture!),
//                                        lastMessage: nil,
//                                        unreadMessagesCount: 0,
//                                        domainName: pushChat.name!,
//                                        threadHash: pushChat.threadhash!)
//        return .domain(channel: channel)
//    }
//
//    func convertPushChatMessageToMessageType(_ pushMessage: PushMessage) -> ChatMessageType? {
//        switch pushMessage.messageType {
//        case .text:
//            var time = Date()
//            if let timestamp = pushMessage.timestamp {
//                time = Date(timeIntervalSince1970: TimeInterval(timestamp))
//            }
//            // TODO: - Review required info to parse chat message
//            let textMessage = ChatTextMessage(id: pushMessage.signature,
//                                              sender: .otherUser(.init(wallet: pushMessage.fromDID)),
//                                              time: time,
//                                              avatarURL: nil,
//                                              text: pushMessage.messageContent) // Decrypt
//            return .text(message: textMessage)
//        default:
//            return nil // Not supported for now
//        }
//    }
    
    func decodeServiceMetadata<T: Codable>(from data: Data?) throws -> T {
        guard let data else {
            throw PushMessagingAPIServiceError.failedToDecodeServiceData
        }
        guard let serviceMetadata = T.objectFromData(data) else {
            throw PushMessagingAPIServiceError.failedToDecodeServiceData
        }
        
        return serviceMetadata
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    struct ChatServiceMetadata: Codable {
        let threadHash: String?
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
