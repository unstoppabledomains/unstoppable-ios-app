//
//  PushConnectionRequest.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

struct PushConnectionRequest: Hashable, Codable {
    let chatId: String?
    let did: String?
    let wallets: String?
    let profilePicture: String?
    let publicKey: String?
    let about: String?
    let name: String?
    let threadhash: String?
    let intent: String?
    let intentSentBy: String?
    let intentTimestamp: Date
    let combinedDID: String
    let groupInformation: PushGroupChatDTO?
}

