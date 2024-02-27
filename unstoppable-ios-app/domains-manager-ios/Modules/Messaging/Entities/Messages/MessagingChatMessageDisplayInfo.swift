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
    var reactions: [MessageReactionDescription] = []
    
    mutating func prepareToDisplay() async {
        if deliveryState == .failedToSend {
            time = Date() 
        }
        switch type {
        case .text, .unknown, .remoteContent, .reaction, .reply:
            return
        case .imageData(var info):
            if info.image == nil {
                info.image = await UIImage.createWith(anyData: info.data)
                self.type = .imageData(info)
            }
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
    var isFailedMessage: Bool {
        deliveryState == .failedToSend
    }
    
    enum DeliveryState: Int {
        case delivered, sending, failedToSend
    }
    
    struct ReactionUIDescription: Hashable {
        let content: String
        let count: Int
        let containsUserReaction: Bool
    }
    
    func buildReactionsUIDescription() -> [ReactionUIDescription] {
        let groupedByContent = [String : [MessageReactionDescription]].init(grouping: reactions, by: { $0.content })
        
        return groupedByContent.map { .init(content: $0.key,
                                            count: $0.value.count,
                                            containsUserReaction: $0.value.first(where: { $0.isUserReaction }) != nil) }
        .sorted(by: { $0.count > $1.count })
    }
}
