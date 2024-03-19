//
//  TestableWalletsDataService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 19.03.2024.
//

import Foundation
@testable import domains_manager_ios
import Combine

final class TestableWalletsDataService: WalletsDataServiceProtocol, FailableService {
    var shouldFail: Bool = false
    
    
    var numberOfGetWalletsCalls = 0
    @Published var wrappedWallets: [WalletEntity] = MockEntitiesFabric.Wallet.mockEntities()
    
    var wallets: [WalletEntity] {
        get {
            numberOfGetWalletsCalls += 1
            return wrappedWallets
        }
        set { wrappedWallets = newValue }
    }
    var walletsPublisher: Published<[WalletEntity]>.Publisher  { $wrappedWallets }
    @Published private(set) var selectedWallet: WalletEntity? = nil
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher { $selectedWallet }
    
    func setSelectedWallet(_ wallet: WalletEntity?) {
        
    }
    
    func refreshDataForWallet(_ wallet: WalletEntity) async throws {
        
    }
    
    func refreshDataForWalletDomain(_ domainName: DomainName) async throws {
        
    }
    
    func didChangeEnvironment() {
        
    }
    
    func didPurchaseDomains(_ purchasedDomains: [PendingPurchasedDomain], pendingProfiles: [DomainProfilePendingChanges]) async {
        
    }
    
    func didMintDomainsWith(domainNames: [String], to wallet: WalletEntity) -> [MintingDomain] {
        []
    }
    
    func loadBalanceFor(walletAddress: HexAddress) async throws -> [WalletTokenPortfolio] {
        []
    }
    
    func loadAdditionalBalancesFor(domainName: DomainName) async -> [WalletTokenPortfolio] {
        []
    }
    
    
}
