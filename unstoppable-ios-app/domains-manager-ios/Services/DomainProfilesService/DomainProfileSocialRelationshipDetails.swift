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
        var domains: [DomainName] = []
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
    }
    
    mutating func applyDetailsFrom(response: DomainProfileFollowersResponse) {
        mutatingSocialDetailsFor(relationshipType: response.relationshipType) { socialDetails in
            
            let responseDomainNames = response.data.map { $0.domain }
            socialDetails.domains.append(contentsOf: responseDomainNames)
            
            socialDetails.paginationInfo.cursor = response.meta.pagination.cursor
            socialDetails.paginationInfo.canLoadMore = responseDomainNames.count == response.meta.pagination.take
        }
    }
    
    private mutating func mutatingSocialDetailsFor(relationshipType: DomainProfileFollowerRelationshipType,
                                                   socialDetailsProvider: (inout SocialDetails)->()) {
        switch relationshipType {
        case .followers:
            socialDetailsProvider(&followersDetails)
        case .following:
            socialDetailsProvider(&followingDetails)
        }
    }
    
    func getFollowersListFor(relationshipType: DomainProfileFollowerRelationshipType) -> [DomainName] {
        switch relationshipType {
        case .followers:
            return followersDetails.domains
        case .following:
            return followingDetails.domains
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
