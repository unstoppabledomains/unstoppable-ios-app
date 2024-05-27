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
    
    var id: String { displayInfo.id }
    var serviceIdentifier: MessagingServiceIdentifier { displayInfo.serviceIdentifier }
    var isApproved: Bool {
        displayInfo.isApproved
    }
    
    func isUpToDateWith(otherChat: MessagingChat) -> Bool {
        serviceMetadata == otherChat.serviceMetadata
    }
     
    func isDeprecatedVersion(of otherChat: MessagingChat) -> Bool {
        switch (displayInfo.type, otherChat.displayInfo.type) {
        case (.community(let lhsCommunity), .community(let rhsCommunity)):
            if displayInfo.id == otherChat.displayInfo.id {
                return false
            }
            
            switch (lhsCommunity.type, rhsCommunity.type) {
            case (.badge(let lhsBadge), .badge(let rhsBadge)):
                return lhsBadge.code == rhsBadge.code
            }
        default:
            return false
        }
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
