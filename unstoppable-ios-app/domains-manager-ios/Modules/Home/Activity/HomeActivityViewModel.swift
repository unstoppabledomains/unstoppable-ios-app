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
    
    private let router: HomeTabRouter
    private var selectedProfile: UserProfile
    private var cancellables: Set<AnyCancellable> = []
    private var txsResponse: WalletTransactionsResponse?
 
    private let userProfileService: UserProfileServiceProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    private let walletTransactionsService: WalletTransactionsServiceProtocol
    
    init(router: HomeTabRouter,
         userProfileService: UserProfileServiceProtocol = appContext.userProfileService,
         walletsDataService: WalletsDataServiceProtocol = appContext.walletsDataService,
         walletTransactionsService: WalletTransactionsServiceProtocol = appContext.walletTransactionsService) {
        self.selectedProfile = router.profile
        self.router = router
        self.userProfileService = userProfileService
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
            return txsResponse?.txs.map {
                WalletTransactionDisplayInfo(serializedTransaction: $0,
                                             userWallet: wallet.address)
            } ?? []
        case .webAccount:
            return []
        }
    }
    
}

// MARK: - Setup methods
private extension HomeActivityViewModel {
    func setup() {
        userProfileService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            if let selectedProfile,
               selectedProfile.id != self?.selectedProfile.id {
                self?.selectedProfile = selectedProfile
                self?.didUpdateSelectedProfile()
            }
        }.store(in: &cancellables)
        
        loadTxsForSelectedProfile(forceReload: true)
    }
    
    func didUpdateSelectedProfile() {
        txsResponse = nil
        loadTxsForSelectedProfile(forceReload: true)
    }
    
    func loadTxsForSelectedProfile(forceReload: Bool) {
        guard case .wallet(let wallet) = selectedProfile else { return }
        
        Task {
            do {
                let txsResponse = try await walletTransactionsService.getTransactionsFor(wallet: wallet.address,
                                                                                         forceReload: forceReload)
                self.txsResponse = txsResponse
            } catch {
                self.error = error
            }
        }
    }
}
