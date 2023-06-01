//
//  MessagingChatMessage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChatMessage: Hashable {
    let displayInfo: MessagingChatMessageDisplayInfo
    let serviceMetadata: Data?
}
