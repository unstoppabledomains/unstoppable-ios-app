//
//  PushChat.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

struct PushChat: Codable, Hashable {
    let chatId: String
    let did: String?
    let wallets: String?
    let profilePicture: String?
    let publicKey: String?
    let about: String?
    let name: String?
    let threadhash: String?
    let intent: String
    let intentSentBy: String
    let intentTimestamp: String
    let combinedDID: String
    let groupInformation: PushGroupChatDTO?
}

