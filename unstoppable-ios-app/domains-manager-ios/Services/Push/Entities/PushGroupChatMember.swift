//
//  PushGroupChatMember.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

struct PushGroupChatMember: Hashable, Codable {
    let wallet: String
    let publicKey: String?
    let isAdmin: Bool
    let image: String
}
