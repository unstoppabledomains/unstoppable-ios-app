//
//  PreviewWalletsDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

final class PreviewWalletsDataService: WalletsDataServiceProtocol {
    func refreshDataForWalletDomain(_ domainName: DomainName) async throws {
        
    }
    
    func didPurchaseDomains(_ purchasedDomains: [PendingPurchasedDomain], pendingProfiles: [DomainProfilePendingChanges]) async {
        
    }
    
    func didMintDomainsWith(domainNames: [String], to wallet: WalletEntity) -> [MintingDomain] {
        []
    }
    
    @Published private(set) var wallets: [WalletEntity] = []
    var walletsPublisher: Published<[WalletEntity]>.Publisher  { $wallets }
    @Published private(set) var selectedWallet: WalletEntity? = nil
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher { $selectedWallet }
    
    init() {
        wallets = MockEntitiesFabric.Wallet.mockEntities()
        selectedWallet = wallets.first
    }
    
    func setSelectedWallet(_ wallet: WalletEntity?) {
        selectedWallet = wallet
    }
    
    func refreshDataForWallet(_ wallet: WalletEntity) async throws {
        
    }
    
    func didChangeEnvironment() {
        
    }
    
    func loadBalanceFor(walletAddress: HexAddress) async throws -> [WalletTokenPortfolio] {
        MockEntitiesFabric.Wallet.mockEntities()[0].balance
    }
    
    func loadAdditionalBalancesFor(domainName: DomainName) async -> [WalletTokenPortfolio] {
        []
    }
}
