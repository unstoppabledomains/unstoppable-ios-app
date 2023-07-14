//
//  ChatsList.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.07.2023.
//

import Foundation

// Namespace
enum ChatsList { }

extension ChatsList {
    enum PresentOptions {
        case `default`
        case showChat(chat: MessagingChatDisplayInfo, profile: MessagingChatUserProfileDisplayInfo)
    }
}
