//
//  MessagingChatDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChatDisplayInfo: Hashable {
    let id: String
    let thisUserDetails: MessagingChatUserDisplayInfo
    let avatarURL: URL?
    let type: MessagingChatType
    var unreadMessagesCount: Int
    var isApproved: Bool
    var lastMessageTime: Date
    var lastMessage: MessagingChatMessageDisplayInfo?
}

// MARK: - Open methods
extension MessagingChatDisplayInfo {
    var isGroupChat: Bool {
        switch type {
        case .private:
            return false
        case .group:
            return true
        }
    }
}

extension Array where Element == MessagingChatDisplayInfo {
    
    func requestsOnly() -> [Element] {
        filter { !$0.isApproved }
    }
    
    func confirmedOnly() -> [Element] {
        filter { $0.isApproved }
    }
    
}
