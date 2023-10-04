//
//  PushGroupChatMember.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation
import Push

struct PushGroupChatMember: Hashable, Codable {
    let wallet: String
    let publicKey: String?
    let isAdmin: Bool
    let image: String?
}

// MARK: - Open methods
extension PushGroupChatMember {
    init(pushMember: Push.PushChat.PushGroup.Member) {
        self.wallet = pushMember.wallet
        self.publicKey = pushMember.publicKey
        self.isAdmin = pushMember.isAdmin
        self.image = pushMember.image
    }
}
