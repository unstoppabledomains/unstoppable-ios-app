//
//  MessagingNewsChannel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2023.
//

import Foundation

struct MessagingNewsChannel {
    let id: String
    let name: String
    let info: String
    let url: String
    let icon: String
    let verifiedStatus: Int
    let activationStatus: Int
    let counter: Int?
    let blocked: Int
    let isAliasVerified: Int
    let subscriberCount: Int
}
