//
//  WalletsDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

final class WalletsDataService {
    
    private let queue = DispatchQueue(label: "com.unstoppable.wallets.data")
    private let storage = WalletEntitiesStorage.instance
    private let domainsService: UDDomainsServiceProtocol
    private let walletsService: UDWalletsServiceProtocol
    private let transactionsService: DomainTransactionsServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private let walletNFTsService: WalletNFTsServiceProtocol
    
    private var selectedWallet: WalletEntity? = nil
    private var wallets: [WalletEntity] = []
    
    init(domainsService: UDDomainsServiceProtocol,
         walletsService: UDWalletsServiceProtocol,
         transactionsService: DomainTransactionsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         walletNFTsService: WalletNFTsServiceProtocol) {
        self.domainsService = domainsService
        self.walletsService = walletsService
        self.transactionsService = transactionsService
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.walletNFTsService = walletNFTsService
        wallets = storage.getCachedWallets()
        ensureConsistencyWithUDWallets()
        setSelectedWallet()
    }
    
}

// MARK: - Private methods
private extension WalletsDataService {
    func refreshDataForWalletAsync(_ wallet: WalletEntity) {
        refreshWalletDomainsAsync(wallet)
        refreshWalletBalancesAsync(wallet)
        refreshWalletNFTsAsync(wallet)
    }
    
    func getUDWallets() -> [UDWallet] {
        walletsService.getUserWallets()
    }
    
    func mutateWalletEntity(_ wallet: WalletEntity, mutationBlock: (inout WalletEntity)->()) {
        queue.sync {
            guard let i = wallets.firstIndex(where: { $0.address == wallet.address }) else { return }
            
            mutationBlock(&wallets[i])
            storage.cacheWallets(wallets)
        }
    }
}

// MARK: - Load domains
private extension WalletsDataService {
    func refreshWalletDomainsAsync(_ wallet: WalletEntity) {
        Task {
            do {
                async let domainsTask = domainsService.updateDomainsList(for: [wallet.udWallet])
                async let reverseResolutionTask = fetchRRDomainNameFor(wallet: wallet)
                let (domains, reverseResolutionMap) = try await (domainsTask, reverseResolutionTask)
                let mintingDomainsNames = MintingDomainsStorage.retrieveMintingDomainsFor(walletAddress: wallet.address).map({ $0.name })
                let pendingPurchasedDomains = getPurchasedDomainsUnlessInList(domains, for: wallet.address)
                
            }
        }
    }
    
    func fetchRRDomainNameFor(wallet: WalletEntity) async -> String? {
        do {
            return try await self.walletsService.reverseResolutionDomainName(for: wallet.address)
        } catch {
            /// If request failed to get current RR domain, use cached value
            return wallet.rrDomain?.name
        }
    }
    
    func getPurchasedDomainsUnlessInList(_ domains: [DomainItem],
                                         for walletAddress: String) -> [DomainItem] {
        let pendingPurchasedDomains = PurchasedDomainsStorage.retrievePurchasedDomainsFor(walletAddress: walletAddress).filter({ pendingDomain in
            domains.first(where: { $0.name == pendingDomain.name }) == nil // Purchased domain not yet reflected in the mirror
        })
        let pendingDomains = pendingPurchasedDomains.map {
            DomainItem(name: $0.name,
                       ownerWallet: $0.walletAddress,
                       blockchain: .Matic)
        }
        PurchasedDomainsStorage.setPurchasedDomains(pendingPurchasedDomains)
        return pendingDomains
    }
}

// MARK: - Load balance temp
private extension WalletsDataService {
    func refreshWalletBalancesAsync(_ wallet: WalletEntity) {
        Task {
            do {
                let walletBalances = try await loadBalanceFor(wallet: wallet)
                
            }
        }
    }
    
    func loadBalanceFor(wallet: WalletEntity) async throws -> [ProfileWalletBalance] {
        // TODO: - Load wallet balance per wallet

        if let domain = wallet.domains.first {
            return try await fetchDomainProfile(domainName: domain.name).walletBalances
        }
        
        let domains = try await domainsService.updateDomainsList(for: [wallet.udWallet])
        if let domain = domains.first {
            return try await fetchDomainProfile(domainName: domain.name).walletBalances
        }
        return []
    }
    
    func fetchDomainProfile(domainName: String) async throws -> SerializedPublicDomainProfile {
        try await NetworkService().fetchPublicProfile(for: domainName, fields: [])
    }
}

// MARK: - Load NFTs temp
private extension WalletsDataService {
    func refreshWalletNFTsAsync(_ wallet: WalletEntity) {
        Task {
            do {
                let walletBalances = try await loadNFTsFor(wallet: wallet)
                
            }
        }
    }
    
    func loadNFTsFor(wallet: WalletEntity) async throws -> [NFTDisplayInfo] {
        // TODO: - Load NFTs per wallet

        if let domain = wallet.domains.first {
            return try await fetchNFTsFor(domainName: domain.name)
        }
        
        let domains = try await domainsService.updateDomainsList(for: [wallet.udWallet])
        if let domain = domains.first {
            return try await fetchNFTsFor(domainName: domain.name)
        }
        return []
    }
    
    func fetchNFTsFor(domainName: String) async throws -> [NFTDisplayInfo] {
        try await walletNFTsService.refreshNFTsFor(domainName: domainName).map { NFTDisplayInfo(nftModel: $0) }
    }
}

// MARK: - Setup methods
private extension WalletsDataService {
    func setSelectedWallet() {
        selectedWallet = wallets.first
    }
    
    func ensureConsistencyWithUDWallets() {
        let udWallets = getUDWallets()
        
        /// Check removed wallets
        let removedWallets = wallets.filter { walletEntity in
            udWallets.first(where: { $0.address == walletEntity.address }) == nil
        }
        if !removedWallets.isEmpty {
            wallets = wallets.filter { walletEntity in
                removedWallets.first(where: { $0.address == walletEntity.address }) != nil
            }
        }
        
        /// Check missing wallets
        let missingWallets = udWallets.filter { udWallet in
            wallets.first(where: { $0.address == udWallet.address }) == nil
        }
        if !missingWallets.isEmpty {
            let newWallets = missingWallets.compactMap { createNewWalletEntityFor(udWallet: $0) }
            wallets.append(contentsOf: newWallets)
        }
        
        let needToUpdateCache = !removedWallets.isEmpty || !missingWallets.isEmpty
        if needToUpdateCache {
            storage.cacheWallets(wallets)
        }
    }
    
    func createNewWalletEntityFor(udWallet: UDWallet) -> WalletEntity? {
        guard let displayInfo = WalletDisplayInfo(wallet: udWallet, domainsCount: 0, udDomainsCount: 0) else { return nil }
        
        return WalletEntity(udWallet: udWallet,
                            displayInfo: displayInfo,
                            domains: [],
                            nfts: [],
                            balance: [],
                            rrDomain: nil)
    }
}

struct WalletEntity: Codable {
    let udWallet: UDWallet
    let displayInfo: WalletDisplayInfo
    var domains: [DomainDisplayInfo]
    var nfts: [NFTDisplayInfo]
    var balance: [ProfileWalletBalance]
    var rrDomain: DomainDisplayInfo?
    
    var address: String { udWallet.address }
}
