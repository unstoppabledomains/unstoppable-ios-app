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
    
    
    
    @Published var wallets: [WalletEntity] = []
    var walletsPublisher: Published<[WalletEntity]>.Publisher  { $wallets }
    @Published private(set) var selectedWallet: WalletEntity? = nil
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher { $selectedWallet }
    
    init() {
        
    }
    
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
