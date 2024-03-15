//
//  WalletDomainProfileDetails.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import Foundation

struct WalletDomainProfileDetails: Hashable {
    
    let walletAddress: HexAddress
    let profileDomainName: DomainName?
    var displayInfo: DomainProfileDisplayInfo?
    var socialDetails: DomainProfileSocialRelationshipDetails?
    
    init(walletAddress: HexAddress, profileDomainName: DomainName? = nil, displayInfo: DomainProfileDisplayInfo? = nil) {
        self.walletAddress = walletAddress
        self.profileDomainName = profileDomainName
        self.displayInfo = displayInfo
        resetSocialDetails()
    }
    
    mutating func resetAllDetails() {
        resetDisplayInfo()
        resetSocialDetails()
    }
    
    mutating func resetDisplayInfo()  {
        displayInfo = nil
    }
    
    mutating func resetSocialDetails() {
        socialDetails = DomainProfileSocialRelationshipDetails(profileDomainName: profileDomainName)
    }
}
