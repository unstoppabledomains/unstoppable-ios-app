//
//  MessagingChat.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChat: Hashable {
    let userId: String
    var displayInfo: MessagingChatDisplayInfo
    let serviceMetadata: Data?
    
    var serviceIdentifier: MessagingServiceIdentifier { displayInfo.serviceIdentifier }
    
    func isUpToDateWith(otherChat: MessagingChat) -> Bool {
        serviceMetadata == otherChat.serviceMetadata
    }
}

extension Array where Element == MessagingChat {
    func sortedByLastMessage() -> [Element] {
        sorted(by: {
            guard let lhsTime = $0.displayInfo.lastMessage?.time else { return false }
            guard let rhsTime = $1.displayInfo.lastMessage?.time else { return true }
            
            return lhsTime > rhsTime
        })
    }
}
