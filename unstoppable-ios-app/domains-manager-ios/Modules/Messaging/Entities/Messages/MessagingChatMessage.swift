//
//  MessagingChatMessage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChatMessage: Hashable {
    var userId: String { displayInfo.userId }
    var id: String { displayInfo.id }
    
    var displayInfo: MessagingChatMessageDisplayInfo
    var serviceMetadata: Data?
}
