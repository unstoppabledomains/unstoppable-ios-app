//
//  MessagingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

//MARK: - This is draft implementation to make UI done.
protocol MessagingServiceProtocol {
    func getChatsListForDomain(_ domain: DomainDisplayInfo,
                              page: Int,
                              limit: Int) async throws -> [MessagingChatDisplayInfo]
    func getMessagesForChat(_ chat: MessagingChatDisplayInfo,
                            fetchLimit: Int) async throws -> [MessagingChatMessageDisplayInfo]
}

//protocol MessagingServiceListener: AnyObject {
//    func messagingChannelsListUpdated(_ channelsList: [ChatChannelType], for user: MessagingChatUserDisplayInfo)
//}
//
//final class MessagingListenerHolder: Equatable {
//
//    weak var listener: MessagingServiceListener?
//
//    init(listener: MessagingServiceListener) {
//        self.listener = listener
//    }
//
//    static func == (lhs: MessagingListenerHolder, rhs: MessagingListenerHolder) -> Bool {
//        guard let lhsListener = lhs.listener,
//              let rhsListener = rhs.listener else { return false }
//
//        return lhsListener === rhsListener
//    }
//
//}
