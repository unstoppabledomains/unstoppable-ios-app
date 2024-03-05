//
//  PreviewPublicDomainProfileDisplayInfoStorageService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

final class PreviewPublicDomainProfileDisplayInfoStorageService: PublicDomainProfileDisplayInfoStorageServiceProtocol {
    
    
    
    func store(profile: PublicDomainProfileDisplayInfo) {
        
    }
    
    func retrieveProfileFor(domainName: DomainName) throws -> PublicDomainProfileDisplayInfo {
        MockEntitiesFabric.PublicDomainProfile.createPublicDomainProfileDisplayInfo(domainName: domainName)
    }
}
