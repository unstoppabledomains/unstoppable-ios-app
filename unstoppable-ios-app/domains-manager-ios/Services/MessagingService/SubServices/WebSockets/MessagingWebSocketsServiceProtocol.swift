//
//  MessagingWebSocketsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingWebSocketsServiceProtocol {
    func subscribeFor(profile: MessagingChatUserProfile,
                      eventCallback: @escaping MessagingWebSocketEventCallback) throws
}

struct MessagingWebSocketMessageEntity {
    let id: String
    let senderDisplayInfo: MessagingChatUserDisplayInfo
    let senderWallet: String
    let receiverWallet: String
    let time: Date
    let type: MessagingChatMessageDisplayType
    let serviceMetadata: Data?
    
    var transformToMessageBlock: ((_ webSocketMessage: MessagingWebSocketMessageEntity, _ chat: MessagingChat)->(MessagingChatMessage))
}
