//
//  MessagingGroupChatDetails.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingGroupChatDetails: Hashable {
    let members: [MessagingChatUserDisplayInfo]
    let pendingMembers: [MessagingChatUserDisplayInfo]
    let name: String
    let adminWallet: String?
    
    var allMembers: [MessagingChatUserDisplayInfo] { members + pendingMembers }
    var displayName: String {
        allMembers.map { $0.displayName }.joined(separator: ", ")
    }
}
