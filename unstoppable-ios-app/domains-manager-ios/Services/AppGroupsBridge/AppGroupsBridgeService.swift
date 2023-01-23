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
}

enum AppGroupDataType: Codable {
    case domainChanges
    case domainAvatarURL(domainName: String)
    
    var key: String {
        switch self {
        case .domainChanges: return "domainChanges"
        case .domainAvatarURL(let domainName): return domainName
        }
    }
}

final class AppGroupsBridgeService {
    
    static let shared: AppGroupsBridgeServiceProtocol = AppGroupsBridgeService()
    private let appGroupsContainer = UserDefaults(suiteName: "group.unstoppabledomains.manager.extensions")!

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
        appGroupsContainer.set(entity?.jsonData(), forKey: type.key)
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
