//
//  DomainProfileSocialRelationshipDetails.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

struct DomainProfileSocialRelationshipDetails: Hashable {
    let walletAddress: HexAddress
    var followersDetails: SocialDetails
    var followingDetails: SocialDetails
    
    init(wallet: WalletEntity) {
        self.walletAddress = wallet.address
        self.followersDetails = SocialDetails(wallet: wallet)
        self.followingDetails = SocialDetails(wallet: wallet)
    }
    
    struct SocialDetails: Hashable {
        private(set) var domainNames: [DomainName] = []
        var paginationInfo: PaginationInfo
        
        init(wallet: WalletEntity) {
            self.paginationInfo = PaginationInfo(wallet: wallet)
        }
        
        struct PaginationInfo: Hashable {
            var cursor: Int? = nil
            var canLoadMore: Bool
            
            init(wallet: WalletEntity) {
                // Only wallet with domain can have followers
                self.canLoadMore = wallet.rrDomain != nil
            }
        }
        
        mutating func addDomainNames(_ domainNames: [DomainName]) {
            let newDomains = domainNames.filter { !self.domainNames.contains($0) }
            self.domainNames.append(contentsOf: newDomains)
        }
    }
    
    mutating func applyDetailsFrom(response: DomainProfileFollowersResponse) {
        mutatingSocialDetailsFor(relationshipType: response.relationshipType) { socialDetails in
            
            let responseDomainNames = response.data.map { $0.domain }
            socialDetails.addDomainNames(responseDomainNames)
            socialDetails.paginationInfo.cursor = response.meta.pagination.cursor
            socialDetails.paginationInfo.canLoadMore = responseDomainNames.count == response.meta.pagination.take
        }
    }
    
    func getFollowersListFor(relationshipType: DomainProfileFollowerRelationshipType) -> [DomainName] {
        switch relationshipType {
        case .followers:
            return followersDetails.domainNames
        case .following:
            return followingDetails.domainNames
        }
    }
    
    func getPaginationInfoFor(relationshipType: DomainProfileFollowerRelationshipType) -> DomainProfileSocialRelationshipDetails.SocialDetails.PaginationInfo {
        switch relationshipType {
        case .followers:
            return followersDetails.paginationInfo
        case .following:
            return followingDetails.paginationInfo
        }
    }
}

// MARK: - Private methods
private extension DomainProfileSocialRelationshipDetails {
    mutating func mutatingSocialDetailsFor(relationshipType: DomainProfileFollowerRelationshipType,
                                           socialDetailsProvider: (inout SocialDetails)->()) {
        switch relationshipType {
        case .followers:
            socialDetailsProvider(&followersDetails)
        case .following:
            socialDetailsProvider(&followingDetails)
        }
    }
}
