//
//  DomainProfileSocialRelationshipDetailsTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import XCTest
@testable import domains_manager_ios

final class DomainProfileSocialRelationshipDetailsTests: BaseTestClass {
    func test_init_setsValuesFromWalletEntityWithProfileDomain() {
        let mockWallet = createMockWallet()
        let details = DomainProfileSocialRelationshipDetails(wallet: mockWallet)
        
        XCTAssertTrue(details.followersDetails.paginationInfo.canLoadMore)
        XCTAssertTrue(details.followingDetails.paginationInfo.canLoadMore)
    }
    
    func test_init_setsValuesFromWalletEntityWithoutProfileDomain() {
        let details = createDetails(profileDomainName: nil)
        
        XCTAssertFalse(details.followersDetails.paginationInfo.canLoadMore)
        XCTAssertFalse(details.followingDetails.paginationInfo.canLoadMore)
    }

    func test_SocialDetails_addDomainNames_filtersDuplicates() {
        var details = DomainProfileSocialRelationshipDetails.SocialDetails(isOwningProfile: true)
        details.addDomainNames(["domain1", "domain2"])
        details.addDomainNames(["domain1"])
        
        XCTAssertEqual(details.domainNames.count, 2)
        XCTAssertTrue(details.domainNames.contains("domain1"))
        XCTAssertTrue(details.domainNames.contains("domain2"))
    }
    
    func test_applyDetailsFrom_updatesFollowersDetails() {
        var details = createDetails()
        let response = responseWithFollowerDomains(["domainA", "domainB"], take: 2)
        details.applyDetailsFrom(response: response)
        XCTAssertEqual(details.followersDetails.domainNames, ["domainA", "domainB"])
        XCTAssertEqual(details.followersDetails.paginationInfo.cursor, 2)
        XCTAssertEqual(details.followersDetails.paginationInfo.canLoadMore, true)
    }

    func test_applyDetailsFrom_updatesFollowersDetailsReachLimit() {
        var details = createDetails()
        let response = responseWithFollowerDomains(["domainA", "domainB"], take: 10)
        details.applyDetailsFrom(response: response)
        XCTAssertEqual(details.followersDetails.paginationInfo.canLoadMore, false)
    }
   
    func test_getFollowersListFor_returnsFollowersList() {
        var details = createDetails()
        details.followersDetails.addDomainNames(["domainA", "domainB"])
        
        let followerList = details.getFollowersListFor(relationshipType: .followers)
        
        XCTAssertEqual(followerList, ["domainA", "domainB"])
    }
    
    func test_getPaginationInfoFor_returnsFollowersPaginationInfo() {
        var details = createDetails()
        details.followersDetails.paginationInfo.cursor = 20
        
        let paginationInfo = details.getPaginationInfoFor(relationshipType: .followers)
        
        XCTAssertEqual(paginationInfo.cursor, 20)
    }
}

// MARK: - Private methods
private extension DomainProfileSocialRelationshipDetailsTests {
    func createDetails(profileDomainName: String? = "preview.x") -> DomainProfileSocialRelationshipDetails {
        let mockWallet = createMockWallet(profileDomainName: profileDomainName)
        return DomainProfileSocialRelationshipDetails(wallet: mockWallet)
    }
    
    func createMockWallet(profileDomainName: String? = "preview.x") -> WalletEntity {
        var wallet = MockEntitiesFabric.Wallet.mockEntities()[0]
        
        var domains: [DomainDisplayInfo] = []
        var rrDomain: DomainDisplayInfo?
        
        if let profileDomainName {
            let domain = DomainDisplayInfo(name: profileDomainName,
                                           ownerWallet: wallet.address,
                                           isSetForRR: true)
            domains.append(domain)
            rrDomain = domain
        }
        
        wallet.updateDomains(domains)
        
        return wallet
    }
    
    func responseWithFollowerDomains(_ domains: [String], take: Int) -> DomainProfileFollowersResponse {
        MockEntitiesFabric.DomainProfile.createFollowersResponseWithDomains(domains,
                                                                            take: take,
                                                                            relationshipType: .followers)
    }
}
