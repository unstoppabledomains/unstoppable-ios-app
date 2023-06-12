//
//  MessagingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

//MARK: - This is draft implementation to make UI done.
protocol MessagingServiceProtocol {
    func refreshChatsForDomain(_ domain: DomainDisplayInfo)
    
    // Chats list
    func getChatsListForDomain(_ domain: DomainDisplayInfo) async throws -> [MessagingChatDisplayInfo]
    
    // Messages
    func getCachedMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo) async throws -> [MessagingChatMessageDisplayInfo]
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            fetchLimit: Int) async throws -> [MessagingChatMessageDisplayInfo]
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChatDisplayInfo) throws -> MessagingChatMessageDisplayInfo
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws
    func resendMessage(_ message: MessagingChatMessageDisplayInfo) throws
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo)
    
    // Channels
    func refreshChannelsForDomain(_ domain: DomainDisplayInfo)
    func getSubscribedChannelsFor(domain: DomainDisplayInfo) async throws -> [MessagingNewsChannel]
    
    // Listeners
    func addListener(_ listener: MessagingServiceListener)
    func removeListener(_ listener: MessagingServiceListener)
}

protocol MessagingServiceListener: AnyObject {
    func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType)
}

final class MessagingListenerHolder: Equatable {

    weak var listener: MessagingServiceListener?

    init(listener: MessagingServiceListener) {
        self.listener = listener
    }

    static func == (lhs: MessagingListenerHolder, rhs: MessagingListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }

        return lhsListener === rhsListener
    }

}

enum MessagingDataType {
    case chats(_ chats: [MessagingChatDisplayInfo], wallet: String)
    case messages(_ messages: [MessagingChatMessageDisplayInfo], chatId: String)
    case channels(_ channels: [MessagingNewsChannel], wallet: String)
}
