//
//  MessagingChat.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChat: Hashable {
    let displayInfo: MessagingChatDisplayInfo
    let serviceMetadata: Data?
}
