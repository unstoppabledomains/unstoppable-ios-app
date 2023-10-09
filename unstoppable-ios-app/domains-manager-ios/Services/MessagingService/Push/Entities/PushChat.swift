//
//  PushChat.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation
import Push

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

extension PushChat {
    init(pushGroup: Push.PushChat.PushGroup, threadHash: String?) {
        let isoFormatter = PushEntitiesTransformer.PushISODateFormatter
        self.chatId = pushGroup.chatId
        self.did = nil
        self.wallets = nil
        self.profilePicture = nil
        self.publicKey = nil
        self.about = nil
        self.name = nil
        self.threadhash = threadHash 
        self.intent = ""
        self.intentSentBy = ""
        self.intentTimestamp = ""
        self.combinedDID = ""
        let members = pushGroup.members.map { PushGroupChatMember(pushMember: $0) }
        let pendingMembers = pushGroup.pendingMembers.map { PushGroupChatMember(pushMember: $0) }
        self.groupInformation = .init(members: members,
                                      pendingMembers: pendingMembers,
                                      contractAddressERC20: pushGroup.contractAddressERC20,
                                      numberOfERC20: pushGroup.numberOfERC20,
                                      contractAddressNFT: pushGroup.contractAddressNFT,
                                      numberOfNFTTokens: pushGroup.numberOfNFTTokens,
                                      verificationProof: pushGroup.verificationProof,
                                      groupImage: pushGroup.groupImage,
                                      groupName: pushGroup.groupName,
                                      isPublic: pushGroup.isPublic,
                                      groupDescription: pushGroup.groupDescription,
                                      groupCreator: pushGroup.groupCreator,
                                      chatId: pushGroup.chatId,
                                      scheduleAt: isoFormatter.date(from: pushGroup.scheduleAt ?? ""),
                                      scheduleEnd: isoFormatter.date(from: pushGroup.scheduleEnd ?? ""),
                                      groupType: pushGroup.groupType)
    }
}
