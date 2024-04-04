//
//  DomainProfilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation
import Combine

protocol DomainProfilesServiceProtocol {
    var followActionsPublisher: PassthroughSubject<DomainProfileFollowActionDetails, Never> { get }
    
    func getCachedDomainProfileDisplayInfo(for domainName: String) -> DomainProfileDisplayInfo?
    func fetchDomainProfileDisplayInfo(for domainName: DomainName) async throws -> DomainProfileDisplayInfo
    func getCachedAndRefreshDomainProfileStream(for domainName: DomainName) -> AsyncThrowingStream<DomainProfileDisplayInfo, Error>
    @discardableResult
    func updateUserDomainProfile(for domain: DomainDisplayInfo,
                                 request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile
    
    func followProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws
    func unfollowProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws
    
    func loadMoreSocialIfAbleFor(relationshipType: DomainProfileFollowerRelationshipType,
                                 in wallet: WalletEntity)
    func publisherForWalletDomainProfileDetails(wallet: WalletEntity) async -> CurrentValueSubject<WalletDomainProfileDetails, Never>
    
    func getSuggestionsFor(domainName: DomainName) async throws -> [DomainProfileSuggestion]
    func getTrendingDomainNames() async throws -> [DomainName]
}
