//
//  XMTPBlockedUsersStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.08.2023.
//

import Foundation

struct XMTPBlockedUsersStorage {
    
    private enum Key: String {
        case xmtpBlockedUsersList
    }
    private let key: Key = .xmtpBlockedUsersList
    
    static let shared = XMTPBlockedUsersStorage()
    
    private init() { }
    
    private func getBlockedUsersList() -> [XMTPBlockedUserDescription] {
        AppGroupsBridgeService.shared.getXMTPBlockedUsersList()
    }
    
    func isOtherUserBlockedInChat(_ chat: MessagingChat) -> Bool {
        switch chat.displayInfo.type {
        case .private:
            let userId = chat.displayInfo.thisUserDetails.wallet
            let chatTopic = chat.displayInfo.id
            let isOtherUserBlocked = isUser(userId,
                                            blockingChatTopic: chatTopic)
            return isOtherUserBlocked
        case .group:
            return false
        }
    }
    
    func isUser(_ userId: String, blockingChatTopic topic: String) -> Bool {
        let blockedUsersList = getBlockedUsersList()
        return blockedUsersList.first(where: { $0.userId == userId && $0.blockedTopic == topic }) != nil
    }
    
    func addBlockedUser(_ blockedUserDescription: XMTPBlockedUserDescription) {
        var blockedUsersList = getBlockedUsersList()
        blockedUsersList.append(blockedUserDescription)
        set(newList: blockedUsersList)
    }
    
    func removeBlockedUser(_ blockedUserDescription: XMTPBlockedUserDescription) {
        var blockedUsersList = getBlockedUsersList()
        blockedUsersList.removeAll(where: { $0 == blockedUserDescription })
        set(newList: blockedUsersList)
    }
    
    private func set(newList: [XMTPBlockedUserDescription]) {
        AppGroupsBridgeService.shared.setXMTPBlockedUsersList(newList)
    }
    
}
