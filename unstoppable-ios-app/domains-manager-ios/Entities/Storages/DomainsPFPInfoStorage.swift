//
//  DomainsPFPInfoStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.12.2022.
//

import Foundation

final class DomainsPFPInfoStorage {
    
    static let domainPFPStorageFileName = "domain-pfps.data"
    
    private init() {}
    static var instance = DomainsPFPInfoStorage()
    private var storage = SpecificStorage<[DomainPFPInfo]>(fileName: DomainsPFPInfoStorage.domainPFPStorageFileName)
    
    func getCachedPFPs() -> [DomainPFPInfo] {
        storage.retrieve() ?? []
    }
    
    func getCachedPFPInfo(for domainName: String) -> DomainPFPInfo? {
        let pfpInfo = getCachedPFPs()
        
        return pfpInfo.first(where: { $0.domainName == domainName })
    }
    
    func saveCachedPFPInfo(_ pfpInfoArray: [DomainPFPInfo]) {
        var pfpInfoCache = getCachedPFPs()
        for pfpInfo in pfpInfoArray {
            if let i = pfpInfoCache.firstIndex(where: { $0.domainName == pfpInfo.domainName }) {
                pfpInfoCache[i] = pfpInfo
            } else {
                pfpInfoCache.append(pfpInfo)
            }
        }
        set(newCachedPFPInfo: pfpInfoCache)
    }
    
    private func set(newCachedPFPInfo: [DomainPFPInfo]) {
        storage.store(newCachedPFPInfo)
    }
}
