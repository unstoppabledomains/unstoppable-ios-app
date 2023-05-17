//
//  ChatMessageType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

enum ChatMessageType: Hashable {
    case text(message: ChatTextMessage)
    
    var time: Date {
        switch self {
        case .text(let message):
            return message.time
        }
    }
}
