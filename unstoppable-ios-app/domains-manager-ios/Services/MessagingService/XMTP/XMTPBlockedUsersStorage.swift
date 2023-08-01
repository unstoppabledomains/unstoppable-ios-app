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
    
    private func getBlockedUsersList() -> [XMTPBlockedUserDescription] {
        guard let data = UserDefaults.standard.object(forKey: key.rawValue) as? Data,
              let usersList = XMTPBlockedUserDescription.objectsFromData(data) else { return [] }
        return usersList
    }
    
    func isUser(_ userId: String, blockingUser otherUserId: String) -> Bool {
        let blockedUsersList = getBlockedUsersList()
        return blockedUsersList.first(where: { $0.userId == userId && $0.blockedUserId == otherUserId }) != nil
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
        let data = newList.jsonData()
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
    
}

struct XMTPBlockedUserDescription: Hashable, Codable {
    let userId: String
    let blockedUserId: String
}
