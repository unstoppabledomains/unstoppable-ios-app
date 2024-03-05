//
//  PreviewDomainProfilesService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

final class PreviewDomainProfilesService: DomainProfilesServiceProtocol {
    func fetchPublicDomainProfileDisplayInfo(for domainName: DomainName) async throws -> PublicDomainProfileDisplayInfo {
        MockEntitiesFabric.PublicDomainProfile.createPublicDomainProfileDisplayInfo(domainName: domainName)
    }
    
}
