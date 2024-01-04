//
//  PreviewMessagingNewsChannel.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

extension MessagingNewsChannel {
    static func mock() -> MessagingNewsChannel {
        MessagingNewsChannel(id: "1",
                             userId: "1",
                             channel: "1",
                             name: "Unstoppable app",
                             info: "Some channel info",
                             url: URL(string: "https://google.com")!,
                             icon: URL(string: "https://google.com")!,
                             verifiedStatus: 1,
                             blocked: 0,
                             subscriberCount: 10,
                             unreadMessagesCount: 0,
                             isCurrentUserSubscribed: true,
                             isSearchResult: false)
    }
}
