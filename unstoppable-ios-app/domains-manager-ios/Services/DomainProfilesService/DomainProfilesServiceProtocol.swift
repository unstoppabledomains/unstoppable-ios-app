//
//  DomainProfilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation
import Combine

protocol DomainProfilesServiceProtocol {
    func fetchPublicDomainProfileDisplayInfo(for domainName: DomainName) async throws -> PublicDomainProfileDisplayInfo
    func followProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws
    func unfollowProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws
    
    func publisherForDomainProfileSocialRelationshipDetails(wallet: WalletEntity) -> CurrentValueSubject<DomainProfileSocialRelationshipDetails, Never>
}
