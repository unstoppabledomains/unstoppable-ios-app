//
//  MessagingChat.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChat: Hashable {
    var displayInfo: MessagingChatDisplayInfo
    let serviceMetadata: Data?
    
    func isUpToDateWith(otherChat: MessagingChat) -> Bool {
        serviceMetadata == otherChat.serviceMetadata
    }
}
