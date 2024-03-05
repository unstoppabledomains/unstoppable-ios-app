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
    private let networkService: NetworkService
    private let numberOfFollowersToTake = 40
    private let serialQueue = DispatchQueue(label: "com.domain_profiles_service.unstoppable")
    private var profilesSocialDetailsCache: [HexAddress : PublishableDomainProfileSocialRelationshipDetails] = [:]

    init(networkService: NetworkService = NetworkService(),
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
                
                let refreshedProfile = try await fetchPublicDomainProfileDisplayInfo(for: domainName)
                continuation.yield(refreshedProfile)
                                
                continuation.finish()
            }
        }
    }

    func followProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.follow(domainName, by: domain.toDomainItem())
    }
    
    func unfollowProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.unfollow(domainName, by: domain.toDomainItem())
    }
    
    ///Get follower details
    ///Load more followers
    ///Subscribe for changes
    func publisherForDomainProfileSocialRelationshipDetails(wallet: WalletEntity) -> CurrentValueSubject<DomainProfileSocialRelationshipDetails, Never> {
        getOrCreateProfileSocialDetailsFor(wallet: wallet).publisher
    }
    
    func loadMoreSocialFor(relationshipType: DomainProfileFollowerRelationshipType,
                           in wallet: WalletEntity) async throws {
        guard let rrDomain = wallet.rrDomain else { throw DomainProfilesServiceError.noDomainForSocialDetails }
        var socialDetails = getOrCreateProfileSocialDetailsFor(wallet: wallet)
        
        guard socialDetails.isAbleToLoadMoreSocialsFor(relationshipType: relationshipType) else { return }
        
        let cursor = socialDetails.getPaginationCursorFor(relationshipType: relationshipType)
        
        let response = try await NetworkService().fetchListOfFollowers(for: rrDomain.name,
                                                                       relationshipType: relationshipType,
                                                                       count: numberOfFollowersToTake,
                                                                       cursor: cursor)
        socialDetails.applyDetailsFrom(response: response)
        saveCachedProfileSocialDetail(socialDetails)
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
    
    struct PublishableDomainProfileSocialRelationshipDetails {
        private var details: DomainProfileSocialRelationshipDetails
        private(set) var publisher: CurrentValueSubject<DomainProfileSocialRelationshipDetails, Never>

        var walletAddress: String { details.walletAddress }
        
        init(wallet: WalletEntity) {
            self.details = DomainProfileSocialRelationshipDetails(wallet: wallet)
            self.publisher = CurrentValueSubject(details)
        }
        
        func getPaginationCursorFor(relationshipType: DomainProfileFollowerRelationshipType) -> Int? {
            details.getPaginationInfoFor(relationshipType: relationshipType).cursor
        }
        
        func isAbleToLoadMoreSocialsFor(relationshipType: DomainProfileFollowerRelationshipType) -> Bool {
            details.getPaginationInfoFor(relationshipType: relationshipType).canLoadMore
        }
        
        mutating func applyDetailsFrom(response: DomainProfileFollowersResponse) {
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
