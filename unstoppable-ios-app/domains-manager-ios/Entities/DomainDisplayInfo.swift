//
//  DomainDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.07.2022.
//

import Foundation

struct DomainDisplayInfo: Hashable {
    
    var name: String
    var ownerWallet: String
    var blockchain: BlockchainType
    var isPrimary: Bool
    var state: State
    var transactionHashes: [HexAddress] = []
    
}

// MARK: - Open methods
extension DomainDisplayInfo {
    var qrCodeURL: URL? {
        URL(string: NetworkConfig.baseDomainProfileUrl + "\(name)")
    }
    
    var pfpAvatarURL: URL? {
        URL(string: NetworkConfig.domainPFPUrl(for: name))
    }
    
    init?(domainItem: DomainItem,
          isPrimary: Bool = false,
          state: State = .default) {
        guard let ownerWallet = domainItem.ownerWallet,
              let blockchain = domainItem.blockchain else { return nil }
        self.name = domainItem.name
        self.transactionHashes = domainItem.transactionHashes
        self.ownerWallet = ownerWallet
        self.blockchain = blockchain
        self.isPrimary = isPrimary
        self.state = state
    }
}

// MARK: - State
extension DomainDisplayInfo {
    enum State {
        case `default`, minting, updatingRecords
    }
}
