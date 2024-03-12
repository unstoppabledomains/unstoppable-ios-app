//
//  PreviewPublicDomainProfileDisplayInfoStorageService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

final class PreviewPublicDomainProfileDisplayInfoStorageService: DomainProfileDisplayInfoStorageServiceProtocol {
    func store(profile: DomainProfileDisplayInfo) {
        
    }
    
    func retrieveProfileFor(domainName: DomainName) throws -> DomainProfileDisplayInfo {
        MockEntitiesFabric.PublicDomainProfile.createPublicDomainProfileDisplayInfo(domainName: domainName)
    }
}
