//
//  MessagingNewsChannelFeed.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation

struct MessagingNewsChannelFeed: Hashable {
    let id: String
    let title: String
    let message: String
    let link: URL
    let time: Date
    var isRead: Bool
    var isFirstInChannel: Bool
}
