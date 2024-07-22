//
//  HomeActivityViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI
import Combine

@MainActor
final class HomeActivityViewModel: ObservableObject, ViewAnalyticsLogger {
    
    var analyticsName: Analytics.ViewName { .homeActivity }
    
    @Published var searchKey: String = ""
    @Published var isKeyboardActive: Bool = false
    @Published var error: Error?
    @Published var selectedChains: [BlockchainType] = []
    @Published var selectedNature: [HomeActivity.TransactionSubject] = []
    @Published var selectedDestination: HomeActivity.TransactionDestination = .all
    
    @Published private var txsResponses: [WalletTransactionsResponse] = []
    @Published private(set) var isLoadingMore = false
    private let router: HomeTabRouter
    private var selectedProfile: UserProfile
    private var cancellables: Set<AnyCancellable> = []
 
    private let userProfilesService: UserProfilesServiceProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    private let walletTransactionsService: WalletTransactionsServiceProtocol
    
    init(router: HomeTabRouter,
         userProfilesService: UserProfilesServiceProtocol = appContext.userProfilesService,
         walletsDataService: WalletsDataServiceProtocol = appContext.walletsDataService,
         walletTransactionsService: WalletTransactionsServiceProtocol = appContext.walletTransactionsService) {
        self.selectedProfile = router.profile
        self.router = router
        self.userProfilesService = userProfilesService
        self.walletsDataService = walletsDataService
        self.walletTransactionsService = walletTransactionsService
        setup()
    }
}

// MARK: - Open methods
extension HomeActivityViewModel {
    var groupedTxs: [HomeActivity.GroupedTransactions] {
        HomeActivity.GroupedTransactions.buildGroupsFrom(txs: txsDisplayInfo)
    }
    
    private var txsDisplayInfo: [WalletTransactionDisplayInfo] {
        switch selectedProfile {
        case .wallet(let wallet):
            var txs: [WalletTransactionDisplayInfo] = txsResponses.flatMap { $0.txs }.map {
                WalletTransactionDisplayInfo(serializedTransaction: $0,
                                             userWallet: wallet.address)
            }
            filterTxsForSelectedNature(&txs)
            filterTxsForSelectedDestination(&txs)
            
            return txs
        case .webAccount:
            return []
        }
    }
    
    func willDisplayTransaction(_ transaction: WalletTransactionDisplayInfo) {
        let txsDisplayInfo = self.txsDisplayInfo.sorted(by: { $0.time > $1.time })
        if txsResponses.first(where: { $0.canLoadMore }) != nil,
           !isLoadingMore,
           let i = txsDisplayInfo.firstIndex(where: { $0 == transaction }),
           i >= txsDisplayInfo.count - 6 {
            loadTxsForSelectedProfileNonBlocking(forceReload: false)
        }
    }
    
    func didPullToRefresh() async {
        await loadTxsForSelectedProfile(forceReload: true)
    }
    
    func didSelectTx(tx: WalletTransactionDisplayInfo) {
        router.pullUp = .custom(.transactionDetailsPullUp(tx: tx))
    }
}

// MARK: - Setup methods
private extension HomeActivityViewModel {
    func setup() {
        userProfilesService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            if let selectedProfile,
               selectedProfile.id != self?.selectedProfile.id {
                self?.selectedProfile = selectedProfile
                self?.didUpdateSelectedProfile()
            }
        }.store(in: &cancellables)
        $selectedChains.sink { [weak self] _ in
            self?.resetAndReloadTxs()
        }.store(in: &cancellables)
        
        loadTxsForSelectedProfileNonBlocking(forceReload: true)
    }
    
    func didUpdateSelectedProfile() {
        resetAndReloadTxs()
    }
    
    func resetAndReloadTxs() {
        txsResponses = []
        loadTxsForSelectedProfileNonBlocking(forceReload: true)
    }
    
    func loadTxsForSelectedProfileNonBlocking(forceReload: Bool) {
        Task {
            await loadTxsForSelectedProfile(forceReload: forceReload)
        }
    }
    
    func loadTxsForSelectedProfile(forceReload: Bool) async {
        guard case .wallet = selectedProfile else { return }
        
        isLoadingMore = true
        do {
            let tokens = getWalletTokens()
            let addresses = Set(tokens.map { $0.address })
            let chainsToLoad: [BlockchainType]? = getChainsListToLoad()
            
            var responses = [WalletTransactionsResponse]()
            try await withThrowingTaskGroup(of: WalletTransactionsResponse.self) { group in
                for address in addresses {
                    group.addTask {
                        try await self.walletTransactionsService.getTransactionsFor(wallet: address, 
                                                                                    chains: chainsToLoad,
                                                                                    forceReload: forceReload)
                    }
                }
                
                for try await response in group {
                    responses.append(response)
                }
            }
            
            self.txsResponses = responses
        } catch {
            self.error = error
        }
        isLoadingMore = false
    }
    
    func getWalletTokens() -> [BalanceTokenUIDescription] {
        guard case .wallet(let wallet) = selectedProfile else { return [] }

        switch wallet.getAssetsType() {
        case .multiChain(let tokens):
            return tokens
        case .singleChain(let token):
            return [token]
        }
    }
    
    func getChainsListToLoad() -> [BlockchainType]? {
        if !selectedChains.isEmpty {
            return selectedChains
        } 
        return nil
    }
    
    func filterTxsForSelectedNature(_ txs: inout [WalletTransactionDisplayInfo]) {
        guard !selectedNature.isEmpty else { return }
        
        txs = txs.filter({ tx in
            let txNature: HomeActivity.TransactionSubject = getNatureOfTx(tx)
            let isTxNatureSelected: Bool = selectedNature.contains(txNature)
            
            return isTxNatureSelected
        })
    }
    
    func getNatureOfTx(_ tx: WalletTransactionDisplayInfo) -> HomeActivity.TransactionSubject {
        if tx.type.isNFT {
            if tx.isDomainNFT {
                return .domain
            } else {
                return .collectible
            }
        }
        return .transfer
    }
    
    func filterTxsForSelectedDestination(_ txs: inout [WalletTransactionDisplayInfo]) {
        switch selectedDestination {
        case .all:
            return
        case .income:
            txs = txs.filter({ $0.type.isDeposit })
        case .outcome:
            txs = txs.filter({ !$0.type.isDeposit })
        }
    }
}
