//
//  MessagingNewsChannel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2023.
//

import Foundation

struct MessagingNewsChannel: Hashable {
    let id: String
    let name: String
    let info: String
    let url: URL
    let icon: URL
    let verifiedStatus: Int
//    let activationStatus: Int
//    let counter: Int?
    let blocked: Int
//    let isAliasVerified: Int
    let subscriberCount: Int
    let unreadMessagesCount: Int
    var lastMessage: MessagingNewsChannelFeed?
}
