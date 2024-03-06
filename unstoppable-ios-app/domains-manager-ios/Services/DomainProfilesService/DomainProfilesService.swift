//
//  DomainProfilesService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation
import Combine

final class DomainProfilesService {
   
    private let storage: PublicDomainProfileDisplayInfoStorageServiceProtocol
    private let networkService: PublicDomainProfileNetworkServiceProtocol
    private let numberOfFollowersToTake = 40
    private let serialQueue = DispatchQueue(label: "com.domain_profiles_service.unstoppable")
    private var profilesSocialDetailsCache: [HexAddress : PublishableDomainProfileSocialRelationshipDetails] = [:]

    init(networkService: PublicDomainProfileNetworkServiceProtocol = NetworkService(),
         storage: PublicDomainProfileDisplayInfoStorageServiceProtocol) {
        self.networkService = networkService
        self.storage = storage
    }
    
}

// MARK: - DomainProfilesServiceProtocol
extension DomainProfilesService: DomainProfilesServiceProtocol {
    func getCachedPublicDomainProfileDisplayInfo(for domainName: String) -> PublicDomainProfileDisplayInfo? {
        try? storage.retrieveProfileFor(domainName: domainName)
    }
 
    func fetchPublicDomainProfileDisplayInfo(for domainName: DomainName) async throws -> PublicDomainProfileDisplayInfo {
        let serializedProfile = try await getSerializedPublicDomainProfile(for: domainName)
        let profile = PublicDomainProfileDisplayInfo(serializedProfile: serializedProfile)
        
        storage.store(profile: profile)
        
        return profile
    }
    
    func getCachedAndRefreshProfileStream(for domainName: DomainName) -> AsyncThrowingStream<PublicDomainProfileDisplayInfo, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if let cachedProfile = getCachedPublicDomainProfileDisplayInfo(for: domainName) {
                    continuation.yield(cachedProfile)
                }
                
                do {
                    let refreshedProfile = try await fetchPublicDomainProfileDisplayInfo(for: domainName)
                    continuation.yield(refreshedProfile)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func followProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.follow(domainName, by: domain.toDomainItem())
    }
    
    func unfollowProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.unfollow(domainName, by: domain.toDomainItem())
    }
    
    func publisherForDomainProfileSocialRelationshipDetails(wallet: WalletEntity) async -> CurrentValueSubject<DomainProfileSocialRelationshipDetails, Never> {
        await getOrCreateProfileSocialDetailsFor(wallet: wallet).publisher
    }
    
    func loadMoreSocialIfAbleFor(relationshipType: DomainProfileFollowerRelationshipType,
                                 in wallet: WalletEntity) {
        Task {
            do {
                guard let profileDomainName = wallet.profileDomainName else { throw DomainProfilesServiceError.noDomainForSocialDetails }
                let socialDetails = getOrCreateProfileSocialDetailsFor(wallet: wallet)
                
                guard await socialDetails.isAbleToLoadMoreSocialsFor(relationshipType: relationshipType) else { return }
                
                await socialDetails.setLoading(relationshipType: relationshipType)
                let cursor = await socialDetails.getPaginationCursorFor(relationshipType: relationshipType)
                
                let response = try await NetworkService().fetchListOfFollowers(for: profileDomainName,
                                                                               relationshipType: relationshipType,
                                                                               count: numberOfFollowersToTake,
                                                                               cursor: cursor)
                await socialDetails.applyDetailsFrom(response: response)
                await socialDetails.setNotLoading(relationshipType: relationshipType)
                saveCachedProfileSocialDetail(socialDetails)
            }
        }
    }
}

// MARK: - Private methods
private extension DomainProfilesService {
    func getSerializedPublicDomainProfile(for domainName: DomainName) async throws -> SerializedPublicDomainProfile {
        let serializedProfile = try await networkService.fetchPublicProfile(for: domainName,
                                                                            fields: [.profile, .records, .socialAccounts])
        return serializedProfile
    }
    
    func getOrCreateProfileSocialDetailsFor(wallet: WalletEntity) -> PublishableDomainProfileSocialRelationshipDetails {
        let walletAddress = wallet.address
        if let cachedDetails = getCachedProfileSocialDetailFor(walletAddress: walletAddress) {
            return cachedDetails
        }
        
        let newDetails = PublishableDomainProfileSocialRelationshipDetails(wallet: wallet)
        saveCachedProfileSocialDetail(newDetails)
        
        return newDetails
    }
    
    func getCachedProfileSocialDetailFor(walletAddress: HexAddress) -> PublishableDomainProfileSocialRelationshipDetails? {
        serialQueue.sync {
            profilesSocialDetailsCache[walletAddress]
        }
    }
    
    func saveCachedProfileSocialDetail(_ details: PublishableDomainProfileSocialRelationshipDetails) {
        serialQueue.sync {
            profilesSocialDetailsCache[details.walletAddress] = details
        }
    }
    
    actor PublishableDomainProfileSocialRelationshipDetails {
        private var details: DomainProfileSocialRelationshipDetails
        private(set) var publisher: CurrentValueSubject<DomainProfileSocialRelationshipDetails, Never>
        private var loadingRelationshipTypes: Set<DomainProfileFollowerRelationshipType> = []
        
        var walletAddress: String { details.walletAddress }
        
        init(wallet: WalletEntity) {
            self.details = DomainProfileSocialRelationshipDetails(wallet: wallet)
            self.publisher = CurrentValueSubject(details)
        }
        
        func getPaginationCursorFor(relationshipType: DomainProfileFollowerRelationshipType) -> Int? {
            details.getPaginationInfoFor(relationshipType: relationshipType).cursor
        }
        
        func isAbleToLoadMoreSocialsFor(relationshipType: DomainProfileFollowerRelationshipType) -> Bool {
            details.getPaginationInfoFor(relationshipType: relationshipType).canLoadMore &&
            !isLoading(relationshipType: relationshipType)
        }
        
        private func isLoading(relationshipType: DomainProfileFollowerRelationshipType) -> Bool {
            loadingRelationshipTypes.contains(relationshipType)
        }
        
        func setLoading(relationshipType: DomainProfileFollowerRelationshipType) {
            loadingRelationshipTypes.insert(relationshipType)
        }
        
        func setNotLoading(relationshipType: DomainProfileFollowerRelationshipType) {
            loadingRelationshipTypes.remove(relationshipType)
        }
        
        func applyDetailsFrom(response: DomainProfileFollowersResponse) {
            details.applyDetailsFrom(response: response)
            publisher.send(details)
        }
    }
}

// MARK: - Open methods
extension DomainProfilesService {
    enum DomainProfilesServiceError: String, LocalizedError {
        case noDomainForSocialDetails
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
