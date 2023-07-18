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
    let adminWallets: [String]
    let isPublic: Bool
    
    var allMembers: [MessagingChatUserDisplayInfo] { members + pendingMembers }
}

// MARK: - Open methods
extension MessagingGroupChatDetails {
    func isUserAdminWith(wallet: String) -> Bool {
        let wallet = wallet.lowercased()
        
        return adminWallets.first(where: { $0.lowercased() == wallet }) != nil
    }
}
