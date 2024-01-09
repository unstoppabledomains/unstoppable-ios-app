//
//  PreviewDataAggregatorService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

struct DataAggregatorService: DataAggregatorServiceProtocol {
    func getWalletsWithInfo() async -> [WalletWithInfo] {
        WalletWithInfo.mock
    }
    
    func getWalletsWithInfoAndBalance(for blockchainType: BlockchainType) async throws -> [WalletWithInfoAndBalance] {
        []
    }
    
    func getWalletDisplayInfo(for wallet: UDWallet) async -> WalletDisplayInfo? {
        nil
    }
    
    func getDomainsWith(names: Set<String>) async -> [DomainItem] {
        []
    }
    
    func setDomainsOrder(using domains: [DomainDisplayInfo]) async {
        
    }
    
    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainDisplayInfo? {
        nil
    }
    
    func isReverseResolutionSetupInProgress(for domainName: DomainName) async -> Bool {
        false
    }
    
    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool {
        true
    }
    
    func isReverseResolutionChangeAllowed(for domain: DomainDisplayInfo) async -> Bool {
        true
    }
    
    func isReverseResolutionSet(for domainName: DomainName) async -> Bool {
        true
    }
    
    func mintDomains(_ domains: [String], paidDomains: [String], domainsOrderInfoMap: SortDomainsOrderInfoMap, to wallet: UDWallet, userEmail: String, securityCode: String) async throws -> [MintingDomain] {
        []
    }
    
    func addListener(_ listener: DataAggregatorServiceListener) {
        
    }
    
    func removeListener(_ listener: DataAggregatorServiceListener) {
        
    }
    
    func getReverseResolutionDomain(for walletAddress: HexAddress) async -> String? {
        nil
    }
    
    func aggregateData(shouldRefreshPFP: Bool) async {
        
    }
    
    func getDomainItems() async -> [DomainItem] {
        []
    }
    
    func getDomainsDisplayInfo() async -> [DomainDisplayInfo] {
        Array([.init(name: "one.x", ownerWallet: "1", isSetForRR: true),
         .init(name: "two.x", ownerWallet: "2", isSetForRR: false),
               .init(name: "three.x", ownerWallet: "3", isSetForRR: false)].prefix(3))
    }
    
    func getDomainWith(name: String) async throws -> DomainItem {
        .init(name: name)
    }
    
    func didPurchaseDomains(_ purchasedDomains: [PendingPurchasedDomain],
                            pendingProfiles: [DomainProfilePendingChanges]) async { }
}
