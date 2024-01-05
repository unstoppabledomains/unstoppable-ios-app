//
//  AppGroupsBridgeService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2022.
//

import Foundation

protocol AppGroupsBridgeServiceProtocol {
    func getDomainChanges() -> [DomainRecordChanges]
    func save(domainRecordsChanges: DomainRecordChanges)
    func clearChanges(for domainName: String)
    func remove(domainRecordChanges: DomainRecordChanges)
    
    func getAvatarPath(for domainName: String) -> String?
    func saveAvatarPath(_ path: String?, for domainName: String)
    
    // XMTP
    func saveXMTPConversationData(conversationData: Data?, topic: String, userWallet: String)
    func getXMTPConversationDataFor(topic: String, userWallet: String) -> Data?
    func getXMTPBlockedUsersList() -> [XMTPBlockedUserDescription]
    func setXMTPBlockedUsersList(_ newList: [XMTPBlockedUserDescription])
}

enum AppGroupDataType: Codable {
    case domainChanges
    case domainAvatarURL(domainName: String)
    case xmtpConversation(topic: String, userWallet: String)
    case xmtpBlockedUsersList
    
    var key: String {
        switch self {
        case .domainChanges: return "domainChanges"
        case .domainAvatarURL(let domainName): return domainName
        case .xmtpConversation(let topic, let userWallet): return "xmtp_\(topic)_\(userWallet)"
        case .xmtpBlockedUsersList: return "xmtpBlockedUsersList"
        }
    }
}

final class AppGroupsBridgeService {
    
    static let shared: AppGroupsBridgeServiceProtocol = AppGroupsBridgeService()
    private let appGroupsContainer = UserDefaults(suiteName: Constants.UnstoppableGroupIdentifier)!

    private init() { }
    
}

// MARK: - AppGroupsBridgeServiceProtocol
extension AppGroupsBridgeService: AppGroupsBridgeServiceProtocol {
    func getDomainChanges() -> [DomainRecordChanges] {
        entityFor(type: .domainChanges) ?? []
    }
    
    func save(domainRecordsChanges: DomainRecordChanges) {
        clearChanges(for: domainRecordsChanges.domainName)
        var changes = getDomainChanges()
        changes.append(domainRecordsChanges)
        save(entity: changes, for: .domainChanges)
    }
    
    func clearChanges(for domainName: String) {
        var changes = getDomainChanges()
        if let i = changes.firstIndex(where: { $0.domainName == domainName }) {
            changes.remove(at: i)
        }
        save(entity: changes, for: .domainChanges)
    }
    
    func remove(domainRecordChanges: DomainRecordChanges) {
        clearChanges(for: domainRecordChanges.domainName)
    }
    
    func getAvatarPath(for domainName: String) -> String? {
        entityFor(type: .domainAvatarURL(domainName: domainName))
    }
    
    func saveAvatarPath(_ path: String?, for domainName: String) {
        save(entity: path, for: .domainAvatarURL(domainName: domainName))
    }
}

// MARK: - XMTP Related
extension AppGroupsBridgeService {
    func saveXMTPConversationData(conversationData: Data?, topic: String, userWallet: String) {
        saveData(conversationData, for: .xmtpConversation(topic: topic, userWallet: userWallet.normalized))
    }
    
    func getXMTPConversationDataFor(topic: String, userWallet: String) -> Data? {
        dataFor(type: .xmtpConversation(topic: topic, userWallet: userWallet.normalized))
    }
    
    func getXMTPBlockedUsersList() -> [XMTPBlockedUserDescription] {
        entityFor(type: .xmtpBlockedUsersList) ?? []
    }
    
    func setXMTPBlockedUsersList(_ newList: [XMTPBlockedUserDescription]) {
        save(entity: newList, for: .xmtpBlockedUsersList)
    }
}

// MARK: - Private methods
private extension AppGroupsBridgeService {
    func dataFor(type: AppGroupDataType) -> Data? {
        appGroupsContainer.object(forKey: type.key) as? Data
    }
    
    func entityFor<T: Codable>(type: AppGroupDataType) -> T? {
        guard let data = dataFor(type: type) else { return nil }
        
        return T.genericObjectFromData(data)
    }
    
    func save<T: Codable>(entity: T?, for type: AppGroupDataType) {
        saveData(entity?.jsonData(), for: type)
    }
    
    func saveData(_ data: Data?, for type: AppGroupDataType) {
        saveData(data, forKey: type.key)
    }
    
    func saveData(_ data: Data?, forKey key: String) {
        appGroupsContainer.set(data, forKey: key)
    }
}
 
struct DomainRecordChanges: Codable, Hashable {
    enum ChangeType: Codable, Hashable {
        case added(_ ticker: String), removed(_ ticker: String), updated(_ ticker: String)
        
        var ticker: String {
            switch self {
            case .added(let ticker), .removed(let ticker), .updated(let ticker):
                return ticker
            }
        }
    }
    
    let domainName: String
    let changes: [ChangeType]
}

struct XMTPBlockedUserDescription: Hashable, Codable {
    let userId: String
    let blockedAddress: String
}

struct XMTPApprovedUserDescription: Hashable, Codable {
    let userId: String
    let approvedAddress: String
}
