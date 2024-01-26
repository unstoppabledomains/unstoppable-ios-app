//
//  HomeTabRouter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

final class HomeTabRouter: ObservableObject {
    @Published var isTabBarVisible: Bool = true
    @Published var tabViewSelection: HomeTab = .wallets
    @Published var pullUp: ViewPullUpConfigurationType?
    @Published var walletViewNavPath: NavigationPath = NavigationPath()
    @Published var presentedNFT: NFTDisplayInfo?
    @Published var presentedDomain: DomainPresentationDetails?
    
    let id: UUID = UUID()
    private var topViews = 0
  
}

// MARK: - Open methods
extension HomeTabRouter {
    @MainActor
    func dismissPullUpMenu() async {
        if pullUp != nil {
            pullUp = nil
            await waitForScreenClosed()
        }
    }
    
    func showDomainProfile(_ domain: DomainDisplayInfo,
                           wallet: WalletEntity,
                           preRequestedAction: PreRequestedProfileAction?,
                           dismissCallback: EmptyCallback?) async {
        await popToRootAndWait()
        tabViewSelection = .wallets
        presentedDomain = .init(domain: domain,
                                wallet: wallet,
                                preRequestedProfileAction: preRequestedAction,
                                dismissCallback: dismissCallback)
    }
}

// MARK: - Pull up related
extension HomeTabRouter {
    func currentPullUp(id: UUID) -> Binding<ViewPullUpConfigurationType?> {
        if topViews != 0 {
            guard self.id != id else {
                return Binding { nil } set: { newValue in }
            }
        } else {
            guard self.id == id else {
                return Binding { nil } set: { newValue in }
            }
        }
        return Binding { [weak self] in
            self?.pullUp
        } set: { [weak self] newValue in
            self?.pullUp = newValue
        }
    }
    
    func registerTopView(id: UUID) {
        topViews += 1
    }
    
    func unregisterTopView(id: UUID) {
        topViews -= 1
        topViews = max(0, topViews)
    }
}

// MARK: - Private methods
private extension HomeTabRouter {
    func popToRoot() {
        presentedNFT = nil
        presentedDomain = nil
        walletViewNavPath = .init()
    }
    
    func popToRootAndWait() async {
        popToRoot()
        await waitForScreenClosed()
    }
    
    func waitForScreenClosed() async {
        await withSafeCheckedMainActorContinuation { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion(Void())
            }
        }
    }
}

// MARK: - DomainPresentationDetails
extension HomeTabRouter {
    struct DomainPresentationDetails: Identifiable {
        var id: String { domain.name }
        
        let domain: DomainDisplayInfo
        let wallet: WalletEntity
        var preRequestedProfileAction: PreRequestedProfileAction? = nil
        var dismissCallback: EmptyCallback? = nil
    }
}
