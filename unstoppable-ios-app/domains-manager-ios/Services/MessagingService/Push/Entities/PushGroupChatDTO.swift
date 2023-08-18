//
//  PushGroupChatDTO.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

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
