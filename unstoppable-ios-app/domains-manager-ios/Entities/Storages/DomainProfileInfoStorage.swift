//
//  DomainProfileInfoStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.11.2022.
//

import Foundation

final class DomainProfileInfoStorage {
    
    static let domainProfilesStorageFileName = "domain-profiles.data"

    private init() {}
    static var instance = DomainProfileInfoStorage()
    
    private var storage = SpecificStorage<[CachedDomainProfileInfo]>(fileName: DomainProfileInfoStorage.domainProfilesStorageFileName)
    
    func getCachedDomainProfiles() -> [CachedDomainProfileInfo] {
        storage.retrieve() ?? []
    }
    
    func getCachedDomainProfile(for domainName: String) -> CachedDomainProfileInfo? {
        let profiles = getCachedDomainProfiles()
        
        return profiles.first(where: { $0.domainName == domainName })
    }
    
    func saveCachedDomainProfile(_ profile: CachedDomainProfileInfo) {
        var profiles = getCachedDomainProfiles()
        if let i = profiles.firstIndex(where: { $0.domainName == profile.domainName }) {
            profiles[i] = profile
        } else {
            profiles.append(profile)
        }
        set(newCachedProfiles: profiles)
    }
    
    private func set(newCachedProfiles: [CachedDomainProfileInfo]) {
        storage.store(newCachedProfiles)
    }
}
