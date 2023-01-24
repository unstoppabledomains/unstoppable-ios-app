//
//  AppGroupsBridgeFromDataAggregatorService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.11.2022.
//

import Foundation

final class AppGroupsBridgeFromDataAggregatorService {
    
    static let shared = AppGroupsBridgeFromDataAggregatorService()
    
    private init() {
        appContext.dataAggregatorService.addListener(self)
    }
    
}

// MARK: - DataAggregatorServiceListener
extension AppGroupsBridgeFromDataAggregatorService: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        switch result {
        case .success(let aggregationResult):
            switch aggregationResult {
            case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                updateDomainsPFPInBridge(domains)
            case .primaryDomainChanged, .walletsListUpdated:
                return
            }
        case .failure:
            return
        }
    }
}

// MARK: - Private methods
private extension AppGroupsBridgeFromDataAggregatorService {
    func updateDomainsPFPInBridge(_ domains: [DomainDisplayInfo]) {
        @Sendable
        func pfpPath(for domain: DomainDisplayInfo) -> String? {
            switch domain.pfpSource {
            case .nft(let imagePath), .nonNFT(let imagePath):
                return imagePath
            case .none:
                return nil
            }
        }
        
        Task.detached(priority: .background) {
            for domain in domains {
                let pfpPath = pfpPath(for: domain)
                AppGroupsBridgeService.shared.saveAvatarPath(pfpPath, for: domain.name)
            }
        }
    }
}
