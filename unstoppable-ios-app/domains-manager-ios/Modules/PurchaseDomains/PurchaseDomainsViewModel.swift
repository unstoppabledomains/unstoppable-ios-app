//
//  PurchaseDomainsViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import Foundation

@MainActor
final class PurchaseDomainsViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var error: Error?
    private var purchaseData: PurchaseData = PurchaseData()
    private let router: HomeTabRouter
    
    var progress: Double {
        if case .purchaseDomains(let navigationDestination) = router.walletViewNavPath.last {
            return navigationDestination.progress
        }
        return 0
    }

    init(router: HomeTabRouter) {
        self.router = router
    }
    
    func handleAction(_ action: PurchaseDomains.FlowAction) {
        Task {
            do {
                switch action {
                case .didSelectDomains(let domains):
                    if domains.count == 1 {
                        pushTo(.fillProfileForDomain(domains[0], viewModel: self))
                    } else {
                        moveToCheckoutWith(domains: domains,
                                           profileChanges: nil)
                    }
                case .didFillProfileForDomain(let domain, let profileChanges):
                    moveToCheckoutWith(domains: [domain],
                                       profileChanges: profileChanges)
                case .didPurchaseDomains:
                    pushTo(.purchased(self))
                case .goToDomains:
                    router.didPurchaseDomains()
                }
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    private func pushTo(_ destination: PurchaseDomains.NavigationDestination) {
        router.walletViewNavPath.append(.purchaseDomains(destination))
    }
    
    private  func moveToCheckoutWith(domains: [DomainToPurchase],
                                     profileChanges: DomainProfilePendingChanges?) {
        
        let wallets = appContext.walletsDataService.wallets
        let selectedWallet: WalletEntity
        if let wallet = appContext.walletsDataService.selectedWallet {
            selectedWallet = wallet
        } else if let wallet = wallets.first {
            selectedWallet = wallet
            appContext.userProfilesService.setActiveProfile(.wallet(wallet))
        } else {
            askUserToAddWalletToPurchase(domains: domains,
                                         profileChanges: profileChanges)
            return
        }
        
        purchaseData.domains = domains
        pushTo(.checkout(.init(domains: domains,
                               profileChanges: profileChanges,
                               selectedWallet: selectedWallet,
                               wallets: wallets)))
    }
    
    
    func askUserToAddWalletToPurchase(domains: [DomainToPurchase],
                                      profileChanges: DomainProfilePendingChanges?) {
        Task {
            do {
                guard let topVC = appContext.coreAppCoordinator.topVC else { return }
                
                let action = try await appContext.pullUpViewService.showAddWalletSelectionPullUp(in: topVC,
                                                                                                 presentationOptions: .addToPurchase,
                                                                                                 actions: WalletDetailsAddWalletAction.allCases)
                await topVC.dismissPullUpMenu()
                
                UDRouter().showAddWalletScreenForAction(action,
                                                        in: topVC,
                                                        addedCallback: { [weak self] result in
                    switch result {
                    case .created, .createdAndBackedUp:
                        self?.moveToCheckoutWith(domains: domains,
                                                 profileChanges: profileChanges)
                    case .cancelled, .failedToAdd:
                        return
                    }
                })
            }
        }
    }
}

// MARK: - Hashable
@MainActor
extension PurchaseDomainsViewModel: Hashable {
    nonisolated static func == (lhs: PurchaseDomainsViewModel, rhs: PurchaseDomainsViewModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(UUID())
    }
}

// MARK: - Private methods
private extension PurchaseDomainsViewModel {
    struct PurchaseData: Hashable {
        var domains: [DomainToPurchase]?
        var wallet: UDWallet? = nil
    }
}

