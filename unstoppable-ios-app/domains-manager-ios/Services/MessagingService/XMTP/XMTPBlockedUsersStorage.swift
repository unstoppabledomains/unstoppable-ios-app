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
    
    func isOtherUserBlockedInChat(_ chat: MessagingChatDisplayInfo) -> Bool {
        switch chat.type {
        case .private:
            let userId = chat.thisUserDetails.wallet
            let chatTopic = chat.id
            let isOtherUserBlocked = isUser(userId,
                                            blockingChatTopic: chatTopic)
            return isOtherUserBlocked
        case .group, .community:
            return false
        }
    }
    
    func isUser(_ userId: String, blockingChatTopic topic: String) -> Bool {
        let blockedUsersList = getBlockedUsersList()
        return blockedUsersList.first(where: { $0.userId == userId && $0.blockedTopic == topic }) != nil
    }
    
    func updatedBlockedUsersListFor(userId: String, blockedTopics: [String]) {
        var blockedUsersList = getBlockedUsersList()
        blockedUsersList.removeAll(where: { $0.userId == userId }) /// Remove all blocked topics list related to user
        
        let blockedUserTopics = blockedTopics.map { XMTPBlockedUserDescription(userId: userId, blockedTopic: $0) } /// Replace it with new data
        blockedUsersList.append(contentsOf: blockedUserTopics)
        
        set(newList: blockedUsersList)
    }
    
    private func set(newList: [XMTPBlockedUserDescription]) {
        AppGroupsBridgeService.shared.setXMTPBlockedUsersList(newList)
    }
    
}
