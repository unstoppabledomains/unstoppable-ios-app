//
//  MessagingCommunitiesChatDetails.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.10.2023.
//

import Foundation

struct MessagingCommunitiesChatDetails: Hashable, Codable {
    let type: CommunityType
    let isJoined: Bool
    let isPublic: Bool
    let members: [MessagingChatUserDisplayInfo]
    let pendingMembers: [MessagingChatUserDisplayInfo]
    let adminWallets: [String]
    
    var allMembers: [MessagingChatUserDisplayInfo] { members + pendingMembers }

    var displayName: String {
        switch type {
        case .badge(let badge):
            return badge.badge.name
        }
    }
    
    var displayIconUrl: String {
        switch type {
        case .badge(let badgeInfo):
            return badgeInfo.badge.logo
        }
    }
}

// MARK: - Open methods
extension MessagingCommunitiesChatDetails {
    func isUserAdminWith(wallet: String) -> Bool {
        let wallet = wallet.lowercased()
        
        return adminWallets.first(where: { $0.lowercased() == wallet }) != nil
    }
}

// MARK: - Open methods
extension MessagingCommunitiesChatDetails {
    enum CommunityType: Hashable, Codable {
        case badge(BadgeDetailedInfo)
    }
}
