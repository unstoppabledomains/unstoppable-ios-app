//
//  PreviewDomainProfileInfoStorage.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

final class DomainProfileInfoStorage {
    
    static let domainProfilesStorageFileName = "domain-profiles.data"
    
    private init() {}
    static var instance = DomainProfileInfoStorage()
    
    
    func getCachedDomainProfiles() -> [CachedDomainProfileInfo] {
        []
    }
    
    func getCachedDomainProfile(for domainName: String) -> CachedDomainProfileInfo? {
        nil
    }
    
    func saveCachedDomainProfile(_ profile: CachedDomainProfileInfo) {
        
    }
    
    private func set(newCachedProfiles: [CachedDomainProfileInfo]) {
        
    }
}
