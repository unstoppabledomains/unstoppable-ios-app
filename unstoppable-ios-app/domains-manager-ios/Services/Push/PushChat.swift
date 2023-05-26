//
//  PushChat.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

struct PushChat: Codable, Hashable {
    let chatId: String
    let did: String
    let wallets: String
    let profilePicture: String
    let publicKey: String
    let about: String
    let name: String
    let threadhash: String
    let intent: String
    let intentSentBy: String
    let intentTimestamp: Date
    let combinedDID: String
    let groupInformation: PushGroupChatDTO?
}

struct PushGroupChatDTO: Hashable, Codable {
    let members: [PushGroupChatMember]
    let pendingMembers: [PushGroupChatMember]
    let contractAddressERC20: String?
    let numberOfERC20: Int
    let contractAddressNFT: String?
    let numberOfNFTTokens: Int
    let verificationProof: String
    let groupImage: String?
    let groupName: String
    let isPublic: Bool
    let groupDescription: String?
    let groupCreator: String
    let chatId: String
    let scheduleAt: Date?
    let scheduleEnd: Date?
    let groupType: String
}

struct PushGroupChatMember: Hashable, Codable {
    let wallet: String
    let publicKey: String?
    let isAdmin: Bool
    let image: String
}
