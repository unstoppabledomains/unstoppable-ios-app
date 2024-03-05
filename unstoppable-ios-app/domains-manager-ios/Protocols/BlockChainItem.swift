//
//  BlockChainItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.12.2022.
//

import Foundation

protocol DomainEntity: Hashable {
    var name: String { get }
    var blockchain: BlockchainType? { get }
    var ownerWallet: String? { get }
}

extension DomainEntity {
    func isSameEntity(_ domainEntity: some DomainEntity) -> Bool {
        name == domainEntity.name
    }
    
    var namingService: NamingService {
//        Leave this till when other chains are introduced
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
        
        return wallet.address.normalized == ownerWallet || wallet.address.normalized == ownerWallet
    }
    
    var isUDDomain: Bool {
        name.isUDTLD()
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

extension DomainEntity {
    func getETHAddress() -> String? {
        guard let walletAddress = ownerWallet else { return nil }
        
        return walletAddress.ethChecksumAddress()
    }
    
    func getETHAddressThrowing() throws -> String {
        guard let address = getETHAddress() else { throw DomainEntityError.noOwnerWalletInDomain }
        
        return address
    }
}

enum DomainEntityError: String, LocalizedError {
    case noOwnerWalletInDomain
    
    public var errorDescription: String? { rawValue }
    
}
