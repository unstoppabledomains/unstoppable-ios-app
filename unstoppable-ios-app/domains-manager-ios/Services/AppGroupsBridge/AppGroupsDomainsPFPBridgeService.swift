//
//  AppGroupsBridgeFromDataAggregatorService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.11.2022.
//

import Foundation
import Combine

final class AppGroupsDomainsPFPBridgeService {
    
    static let shared = AppGroupsDomainsPFPBridgeService()
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        appContext.walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            let domains = wallets.combinedDomains()
            self?.updateDomainsPFPInBridge(domains)
        }.store(in: &cancellables)
    }
    
}

// MARK: - Private methods
private extension AppGroupsDomainsPFPBridgeService {
    func updateDomainsPFPInBridge(_ domains: [DomainDisplayInfo]) {
        @Sendable
        func pfpPath(for domain: DomainDisplayInfo) -> String? {
            switch domain.pfpSource {
            case .nft(let imagePath), .nonNFT(let imagePath):
                return imagePath
            case .none, .local:
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
