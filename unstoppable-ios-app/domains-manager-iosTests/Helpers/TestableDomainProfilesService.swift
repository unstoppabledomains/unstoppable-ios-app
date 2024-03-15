//
//  TestableDomainProfilesService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import Foundation
@testable import domains_manager_ios
import Combine

final class TestableDomainProfilesService: DomainProfilesServiceProtocol, FailableService {
    
    private(set) var followActionsPublisher = PassthroughSubject<DomainProfileFollowActionDetails, Never>()
    
    var shouldFail: Bool = false
    var publisher = CurrentValueSubject<WalletDomainProfileDetails, Never>(.init(walletAddress: "0x1"))
    var loadMoreCallsHistory: [DomainProfileFollowerRelationshipType] = []
    var loadSuggestionsCallsHistory: [HexAddress] = []
    var profilesSuggestions: [DomainProfileSuggestion] = MockEntitiesFabric.ProfileSuggestions.createSuggestionsForPreview()
    
    func getCachedDomainProfileDisplayInfo(for domainName: String) -> DomainProfileDisplayInfo? {
        nil
    }
    
    func fetchDomainProfileDisplayInfo(for domainName: DomainName) async throws -> DomainProfileDisplayInfo {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func getCachedAndRefreshDomainProfileStream(for domainName: DomainName) -> AsyncThrowingStream<DomainProfileDisplayInfo, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: TestableGenericError.generic)
        }
    }
    
    func updateUserDomainProfile(for domain: DomainDisplayInfo, request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func followProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try failIfNeeded()
    }
    
    func unfollowProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try failIfNeeded()
    }
    
    func loadMoreSocialIfAbleFor(relationshipType: DomainProfileFollowerRelationshipType, in wallet: WalletEntity) {
        loadMoreCallsHistory.append(relationshipType)
    }
    
    func getSuggestionsFor(wallet: WalletEntity) async throws -> [DomainProfileSuggestion] {
        loadSuggestionsCallsHistory.append(wallet.address)
        try failIfNeeded()
        return profilesSuggestions
    }
    
    func publisherForWalletDomainProfileDetails(wallet: WalletEntity) async -> CurrentValueSubject<WalletDomainProfileDetails, Never> {
        publisher
    }
    
    func getTrendingDomainNames() async throws -> [domains_manager_ios.DomainName] {
        []
    }
}
