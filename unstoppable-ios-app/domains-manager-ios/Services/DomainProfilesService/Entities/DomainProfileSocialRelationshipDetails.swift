//
//  DomainProfileSocialRelationshipDetails.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

struct DomainProfileSocialRelationshipDetails: Hashable {
    
    var followersDetails: SocialDetails
    var followingDetails: SocialDetails
    
    init(profileDomainName: DomainName?) {
        
        let isOwningProfile = profileDomainName != nil
        self.followersDetails = SocialDetails(isOwningProfile: isOwningProfile)
        self.followingDetails = SocialDetails(isOwningProfile: isOwningProfile)
    }
    
    init(wallet: WalletEntity) {
        self.init(profileDomainName: wallet.profileDomainName)
    }
    
    struct SocialDetails: Hashable {
        private(set) var domainNames: [DomainName] = []
        var paginationInfo: PaginationInfo
        
        init(isOwningProfile: Bool) {
            self.paginationInfo = PaginationInfo(isOwningProfile: isOwningProfile)
        }
        
        struct PaginationInfo: Hashable {
            var cursor: Int? = nil
            var canLoadMore: Bool
            
            init(isOwningProfile: Bool) {
                // Only wallet with domain can have followers
                self.canLoadMore = isOwningProfile
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
