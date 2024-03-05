//
//  DomainProfilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation
import Combine

protocol DomainProfilesServiceProtocol {
    func getCachedPublicDomainProfileDisplayInfo(for domainName: String) -> PublicDomainProfileDisplayInfo?
    func fetchPublicDomainProfileDisplayInfo(for domainName: DomainName) async throws -> PublicDomainProfileDisplayInfo
    func getCachedAndRefreshProfileStream(for domainName: DomainName) -> AsyncThrowingStream<PublicDomainProfileDisplayInfo, Error>
    func followProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws
    func unfollowProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws
    
    func loadMoreSocialIfAbleFor(relationshipType: DomainProfileFollowerRelationshipType,
                                 in wallet: WalletEntity)
    func publisherForDomainProfileSocialRelationshipDetails(wallet: WalletEntity) -> CurrentValueSubject<DomainProfileSocialRelationshipDetails, Never>
}
