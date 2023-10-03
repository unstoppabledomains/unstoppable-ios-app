//
//  XMTPApprovedUsersStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.10.2023.
//

import Foundation

struct XMTPApprovedTopicsStorage {
    static let storageFileName = "xmtp-approved-topics.data"
    
    private init() {}
    static var shared = XMTPApprovedTopicsStorage()
    private var storage = SpecificStorage<[XMTPApprovedUserDescription]>(fileName: XMTPApprovedTopicsStorage.storageFileName)

    func getApprovedTopicsListFor(userId: String) -> [XMTPApprovedUserDescription] {
        let list = storage.retrieve() ?? []
        return list.filter { $0.userId == userId }
    }
    
    func updatedApprovedUsersListFor(userId: String, approvedTopics: [String]) {
        var approvedUsersList = getAllApprovedTopicsList()
        approvedUsersList.removeAll(where: { $0.userId == userId }) /// Remove all approved topics list related to user
        
        let approvedUserTopics = approvedTopics.map { XMTPApprovedUserDescription(userId: userId, approvedTopic: $0) } /// Replace it with new data
        approvedUsersList.append(contentsOf: approvedUserTopics)
        
        set(newList: approvedUsersList)
    }
    
    private func getAllApprovedTopicsList() -> [XMTPApprovedUserDescription] {
        storage.retrieve() ?? []
    }
    
    private func set(newList: [XMTPApprovedUserDescription]) {
        storage.store(newList)
    }
    
}
