//
//  PushMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

final class PushMessagingAPIService {
    
    private let pushService: PushAPIService = PushAPIService()
    
}

// MARK: - MessagingAPIServiceProtocol
extension PushMessagingAPIService: MessagingAPIServiceProtocol {
    func getUserFor(domain: DomainItem) async throws -> ChatUser {
        let pushUser = try await pushService.getUser(for: domain)
        let chatUser = convertPushUserToChatUser(pushUser)
        return chatUser
    }
    
    func createUser(for domain: DomainItem) async throws -> ChatUser {
        let pushUser = try await pushService.createUser(for: domain)
        let chatUser = convertPushUserToChatUser(pushUser)
        return chatUser
    }
    
    func getChannels(for domain: DomainDisplayInfo,
                     page: Int,
                     limit: Int ) async throws -> [ChatChannelType] {
        let pushChats = try await pushService.getChats(for: domain,
                                                       page: page,
                                                       limit: limit)
        let channelTypes = pushChats.map({ convertPushChatToChannelType($0) })
        return channelTypes
    }
    
    func getMessagesForChannel(_ channel: ChatChannelType,
                               fetchLimit: Int) async throws -> [ChatMessageType] {
        let threadHash = channel.channel.threadHash
        let pushMessages = try await pushService.getChatMessages(threadHash: threadHash, fetchLimit: fetchLimit)
        let messageTypes = pushMessages.compactMap({ convertPushChatMessageToMessageType($0) })
        return messageTypes
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    func convertPushUserToChatUser(_ pushUser: PushUser) -> ChatUser {
        ChatUser(wallet: pushUser.wallets,
                 avatarURL: pushUser.profilePicture,
                 about: pushUser.about,
                 name: pushUser.name)
    }
    
    func convertPushChatToChannelType(_ pushChat: PushChat) -> ChatChannelType {
        let channel = DomainChatChannel(id: pushChat.chatId,
                                        avatarURL: URL(string: pushChat.profilePicture),
                                        lastMessage: nil,
                                        unreadMessagesCount: 0,
                                        domainName: pushChat.name,
                                        threadHash: pushChat.threadhash)
        return .domain(channel: channel)
    }
    
    func convertPushChatMessageToMessageType(_ pushMessage: PushMessage) -> ChatMessageType? {
        switch pushMessage.messageType {
        case .text:
            var time = Date()
            if let timestampt = pushMessage.timestamp {
                time = Date(timeIntervalSince1970: TimeInterval(timestampt))
            }
            // TODO: - Review required info to parse chat message
            let textMessage = ChatTextMessage(id: pushMessage.signature,
                                              sender: .friend,
                                              time: time,
                                              avatarURL: nil,
                                              text: pushMessage.messageContent) // Decrypt
            return .text(message: textMessage)
        default:
            return nil // Not supported for now
        }
    }
}

// MARK: - Open methods
extension PushMessagingAPIService {
    enum PushMessagingAPIServiceError: Error {
        case incorrectDataState
    }
}
