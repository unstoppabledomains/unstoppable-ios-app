//
//  PreviewDomainItem.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

struct DomainItem: DomainEntity {
    var name = ""
    var ownerWallet: String? = ""
    var blockchain: BlockchainType? = .Matic
    
    func doesRequirePayment() -> Bool {
        switch self.getBlockchainType() {
        case .Ethereum, .Base: return true
        case .Matic: return false
        }
    }
}


struct PublicDomainDisplayInfo: Hashable {
    let walletAddress: String
    let name: String
}
