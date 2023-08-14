//
//  MessagingChatMessageDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import UIKit

struct MessagingChatMessageDisplayInfo: Hashable {
    let id: String
    let chatId: String
    let userId: String
    let senderType: MessagingChatSender
    var time: Date
    var type: MessagingChatMessageDisplayType
    var isRead: Bool
    var isFirstInChat: Bool
    var deliveryState: DeliveryState
    var isEncrypted: Bool
    
    mutating func prepareToDisplay() async {
        if deliveryState == .failedToSend {
            time = Date() 
        }
        switch type {
        case .text, .unknown, .imageData, .remoteContent:
            return
        case .imageBase64(var info):
            if info.image == nil {
                info.image = await UIImage.from(base64String: info.base64Image)
                self.type = .imageBase64(info)
            }
        }
    }
}

// MARK: - Open methods
extension MessagingChatMessageDisplayInfo {
    enum DeliveryState: Int {
        case delivered, sending, failedToSend
    }
}
