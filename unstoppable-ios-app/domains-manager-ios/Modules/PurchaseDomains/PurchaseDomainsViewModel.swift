//
//  PurchaseDomainsViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import Foundation

@MainActor
final class PurchaseDomainsViewModel: ObservableObject {
    
    static private var didCheckLocation = false
    
    @Published var isLoading = false
    @Published var error: Error?
    @Published var localCart = PurchaseDomains.LocalCart()
    let id = UUID().uuidString
    private var purchaseData: PurchaseData = PurchaseData()
    private let router: HomeTabRouter
    
    var progress: Double {
        if case .purchaseDomains(let navigationDestination) = router.walletViewNavPath.last {
            return navigationDestination.progress
        }
        return 0
    }
    
    private var previousProgress: Double {
        let path = router.walletViewNavPath
        let i = path.count - 2
        guard path.indices.contains(i) else { return 0 }
        if case .purchaseDomains(let navigationDestination) = path[i] {
            return navigationDestination.progress
        }
        return 0
    }
    
    func progressFor(swipeBackProgress: Double) -> Double {
        let previousProgress = self.previousProgress
        let currentProgress = progress
        let progressDiff: Double = currentProgress - previousProgress
        let progressDiffAccordingToSwipeBackProgress: Double = progressDiff * (1 - swipeBackProgress)
        let result: Double = previousProgress + progressDiffAccordingToSwipeBackProgress
        
        return result
    }
    
    init(router: HomeTabRouter) {
        self.router = router
        updateUserSettingsForCurrentLocation()
    }
    
    func handleAction(_ action: PurchaseDomains.FlowAction) {
        Task {
            do {
                switch action {
                case .didSelectDomains(let domains):
                    moveToCheckoutWith(domains: domains,
                                       profileChanges: nil)
                case .didFillProfileForDomain(let domain, let profileChanges):
                    moveToCheckoutWith(domains: [domain],
                                       profileChanges: profileChanges)
                case .didRemoveAllDomainsFromTheCart:
                    localCart.clearCart()
                    router.walletViewNavPath.removeLast()
                    appContext.toastMessageService.showToast(.cartCleared, isSticky: false)
                case .didPurchaseDomains(let purchasedDomainsData):
                    pushTo(.purchased(purchasedDomainsData, viewModel: self))
                case .goToDomains:
                    router.didPurchaseDomains()
                }
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsViewModel {
    func pushTo(_ destination: PurchaseDomains.NavigationDestination) {
        router.walletViewNavPath.append(.purchaseDomains(destination))
    }
    
    func moveToCheckoutWith(domains: [DomainToPurchase],
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
                               wallets: wallets),
                         viewModel: self))
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
    
    func updateUserSettingsForCurrentLocation() {
        guard !Self.didCheckLocation else { return }
        
        Task {
            do {
                let isInTheUS = try await appContext.ipVerificationService.isUserInTheUS()
                let purchaseLocation = PurchaseDomainsPreferencesStorage.shared.checkoutData.purchaseLocation
                
                if isInTheUS,
                   case .other = purchaseLocation {
                    PurchaseDomainsPreferencesStorage.shared.checkoutData.purchaseLocation = .usa
                } else if !isInTheUS,
                          case .usa = purchaseLocation,
                          PurchaseDomainsPreferencesStorage.shared.checkoutData.zipCodeIfEntered == nil {
                    PurchaseDomainsPreferencesStorage.shared.checkoutData.purchaseLocation = .other
                }
                
                Self.didCheckLocation = true
            } catch { }
        }
    }
}

// MARK: - Hashable
@MainActor
extension PurchaseDomainsViewModel: Hashable {
    nonisolated static func == (lhs: PurchaseDomainsViewModel, rhs: PurchaseDomainsViewModel) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Private methods
private extension PurchaseDomainsViewModel {
    struct PurchaseData: Hashable {
        var domains: [DomainToPurchase]?
        var wallet: UDWallet? = nil
    }
}

