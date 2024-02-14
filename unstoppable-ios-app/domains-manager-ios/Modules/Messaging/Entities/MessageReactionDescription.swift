//
//  MessageReactionDescription.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.02.2024.
//

import Foundation

struct MessageReactionDescription: Hashable {
    let content: String
    let messageId: String
    let referenceMessageId: String
    let isUserReaction: Bool
}
