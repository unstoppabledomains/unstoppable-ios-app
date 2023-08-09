//
//  MessagingNewsChannel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2023.
//

import Foundation

struct MessagingNewsChannel: Hashable {
    let id: String
    let userId: String 
    let channel: String
    let name: String
    let info: String
    let url: URL
    let icon: URL
    let verifiedStatus: Int
    let blocked: Int
    let subscriberCount: Int
    let unreadMessagesCount: Int
    var isCurrentUserSubscribed: Bool
    var isSearchResult: Bool
    var lastMessage: MessagingNewsChannelFeed?
}

extension Array where Element == MessagingNewsChannel {
    func sortedByLastMessage() -> [Element] {
        sorted(by: {
            if $0.lastMessage?.time == nil,
               $1.lastMessage?.time == nil {
                return $0.name < $1.name
            }
            guard let lhsTime = $0.lastMessage?.time else { return false }
            guard let rhsTime = $1.lastMessage?.time else { return true }
            
            return lhsTime > rhsTime
        })
    }
}
