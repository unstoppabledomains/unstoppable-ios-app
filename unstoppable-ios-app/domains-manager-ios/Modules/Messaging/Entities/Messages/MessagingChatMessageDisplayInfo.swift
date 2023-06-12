//
//  MessagingChatMessageDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChatMessageDisplayInfo: Hashable {
    let id: String
    let chatId: String
    let senderType: MessagingChatSender
    let time: Date
    var type: MessagingChatMessageDisplayType
    var isRead: Bool
    var isFirstInChat: Bool
    var deliveryState: DeliveryState
}

// MARK: - Open methods
extension MessagingChatMessageDisplayInfo {
    enum DeliveryState: Int {
        case delivered, sending, failedToSend
    }
}
