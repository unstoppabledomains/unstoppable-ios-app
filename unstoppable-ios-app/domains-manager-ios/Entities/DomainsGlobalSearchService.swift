//
//  DomainsGlobalSearchService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

final class DomainsGlobalSearchService {
    
    var shouldResolveFullWalletAddress = true
    
    typealias SearchProfilesTask = Task<[SearchDomainProfile], Error>
    private var currentTask: SearchProfilesTask?
    
    init(shouldResolveFullWalletAddress: Bool = true) {
        self.shouldResolveFullWalletAddress = shouldResolveFullWalletAddress
    }
    
    func searchForGlobalProfilesExcludingUsers(with searchKey: String,
                                               walletsDataService: WalletsDataServiceProtocol) async throws -> [SearchDomainProfile] {
        let profiles = try await searchForGlobalProfiles(with: searchKey)
        let userDomains = walletsDataService.wallets.combinedDomains()
        let userDomainsNames = Set(userDomains.map({ $0.name }))
        return profiles.filter({ !userDomainsNames.contains($0.name) && $0.ownerAddress != nil })
    }
    
    func searchForGlobalProfiles(with searchKey: String) async throws -> [SearchDomainProfile] {
        // Cancel previous search task if it exists
        currentTask?.cancel()
        let searchKey = searchKey.trimmedSpaces.lowercased()
        
        let task: SearchProfilesTask = Task.detached {
            do {
                try Task.checkCancellation()
                
                let profiles = try await self.searchForDomains(searchKey: searchKey)
                
                try Task.checkCancellation()
                return profiles
            } catch NetworkLayerError.requestCancelled, is CancellationError {
                return []
            } catch {
                throw error
            }
        }
        
        currentTask = task
        let users = try await task.value
        return users
    }
    
    private func searchForDomains(searchKey: String) async throws -> [SearchDomainProfile] {
        if searchKey.isValidAddress() {
            guard shouldResolveFullWalletAddress else { return [] }
            
            let wallet = searchKey
            if let domain = try? await loadGlobalDomainRRInfo(for: wallet) {
                return [domain]
            }
            
            return []
        } else {
            let domains = try await NetworkService().searchForDomainsWith(name: searchKey, shouldBeSetAsRR: false)
            return domains
        }
    }
    
    private func loadGlobalDomainRRInfo(for key: String) async throws -> SearchDomainProfile? {
        if let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: key.lowercased()) {
            return SearchDomainProfile(name: rrInfo.name,
                                       ownerAddress: rrInfo.address,
                                       imagePath: rrInfo.pfpURLToUse?.absoluteString,
                                       imageType: .offChain)
        }
        
        return nil
    }
}
