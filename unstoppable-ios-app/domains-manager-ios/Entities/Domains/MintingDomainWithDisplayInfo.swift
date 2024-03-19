//
//  MintingDomainWithDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.01.2023.
//

import Foundation

struct MintingDomainWithDisplayInfo {
    
    let mintingDomain: MintingDomain
    let displayInfo: DomainDisplayInfo
    
    init(mintingDomain: MintingDomain, displayInfo: DomainDisplayInfo) {
        self.mintingDomain = mintingDomain
        self.displayInfo = displayInfo
    }
    
    init(displayInfo: DomainDisplayInfo) {
        self.mintingDomain = .init(name: displayInfo.name,
                                   walletAddress: displayInfo.ownerWallet ?? "",
                                   isPrimary: displayInfo.isPrimary)
        self.displayInfo = displayInfo
    }
}
