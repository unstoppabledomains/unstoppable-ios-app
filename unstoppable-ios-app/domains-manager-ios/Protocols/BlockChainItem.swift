//
//  BlockChainItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.12.2022.
//

import Foundation

protocol DomainEntity: Equatable {
    var name: String { get }
    var blockchain: BlockchainType? { get }
    var ownerWallet: String? { get }
}

extension DomainEntity {
    func isSameEntity(_ domainEntity: some DomainEntity) -> Bool {
        name == domainEntity.name
    }
    
    var namingService: NamingService {
        let blockchain = getBlockchainType()
        if blockchain == .Zilliqa {
            return NamingService.ZNS
        }
        return NamingService.UNS
    }
    
    func getBlockchainType() -> BlockchainType {
        if let blockchain = self.blockchain {
            return blockchain
        }
        Debugger.printWarning("Domain with no blockchain property")
        return .Matic
    }
    
    func isOwned(by wallets: [UDWallet]) -> Bool {
        for wallet in wallets where isOwned(by: wallet) {
            return true
        }
        return false
    }
    
    func isOwned(by wallet: UDWallet) -> Bool {
        guard let ownerWallet = self.ownerWallet?.normalized else { return false }
        
        return wallet.extractEthWallet()?.address.normalized == ownerWallet || wallet.extractZilWallet()?.address.normalized == ownerWallet
    }
}

extension Array where Element: DomainEntity {
    func changed(domain: Element) -> Element? {
        if let domainInArray = self.first(where: { $0.name == domain.name }),
           domainInArray != domain {
            return domainInArray
        }
        return nil
    }
    
    mutating func remove(domains: [Element]) {
        guard domains.count > 0 else { return }
        let domainNames = domains.map({$0.name})
        let indeces = self.enumerated()
            .filter({domainNames.contains($0.element.name)})
            .map({$0.offset})
        self.remove(at: indeces)
    }
}
