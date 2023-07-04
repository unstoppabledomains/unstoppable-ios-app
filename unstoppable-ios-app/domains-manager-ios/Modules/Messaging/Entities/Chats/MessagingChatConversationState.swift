//
//  MessagingChatConversationState.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import Foundation

enum MessagingChatConversationState {
    case newChat(MessagingChatUserDisplayInfo)
    case existingChat(MessagingChatDisplayInfo)
}
