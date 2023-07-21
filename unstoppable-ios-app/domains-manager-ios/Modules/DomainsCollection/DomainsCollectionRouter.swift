//
//  DomainsCollectionRouter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.06.2022.
//

import UIKit

@MainActor
protocol DomainsCollectionRouterProtocol {
    func showSettings(loginCallback: @escaping LoginFlowNavigationController.LoggedInCallback)
    func showQRScanner(selectedDomain: DomainDisplayInfo)
    func showDomainProfile(_ domain: DomainDisplayInfo,
                           wallet: UDWallet,
                           walletInfo: WalletDisplayInfo,
                           dismissCallback: EmptyCallback?) async
    func isMintingAvailable(in viewController: UIViewController) async -> Bool
    func runMintDomainsFlow(with mode: MintDomainsNavigationController.Mode)
    func showImportWalletsWith(initialAction: WalletsListViewPresenter.InitialAction)
    func showBuyDomainsWebView()
    func isTopPresented() -> Bool
    func showAppUpdateRequired()
    func showDomainsSearch(_ domains: [DomainDisplayInfo],
                           searchCallback: @escaping DomainsListSearchCallback)
    func showChatsListScreen()
}

@MainActor
final class DomainsCollectionRouter: UDRouter {
    
    private let dataAggregatorService = appContext.dataAggregatorService
    private let networkReachabilityService: NetworkReachabilityServiceProtocol? = appContext.networkReachabilityService
    weak var viewController: DomainsCollectionViewController?
    weak var navigationController: CNavigationController?
    weak var presenter: DomainsCollectionPresenter?
    
    func configureViewController(mintingState: DomainsCollectionMintingState) -> UIViewController {
        let domainsCollectionVC = DomainsCollectionViewController.nibInstance()
        let presenter = DomainsCollectionPresenter(view: domainsCollectionVC,
                                                   router: self,
                                                   dataAggregatorService: dataAggregatorService,
                                                   initialMintingState: mintingState,
                                                   notificationsService: appContext.notificationsService,
                                                   udWalletsService: appContext.udWalletsService,
                                                   appLaunchService: appContext.appLaunchService)
        domainsCollectionVC.presenter = presenter
        let nav = CNavigationController(rootViewController: domainsCollectionVC)
        
        self.viewController = domainsCollectionVC
        self.presenter = presenter
        self.navigationController = nav
        
        return nav
    }
}

// MARK: - DomainsCollectionRouterProtocol
extension DomainsCollectionRouter: DomainsCollectionRouterProtocol {
    func showImportWalletsWith(initialAction: WalletsListViewPresenter.InitialAction) {
        guard let navigationController = self.navigationController,
            let viewController = self.viewController else { return }

        let walletsListVC = buildWalletsListModule(initialAction: initialAction)
        let viewControllers = [viewController, walletsListVC]
        navigationController.setViewControllers(viewControllers, animated: true)
    }
    
    func showSettings(loginCallback: @escaping LoginFlowNavigationController.LoggedInCallback) {
        guard let navigationController = self.navigationController else { return }
        
        showSettings(in: navigationController, loginCallback: { [weak self] result in
            loginCallback(result)
            switch result {
            case .cancel, .failedToLoadParkedDomains:
                return
            case .loggedIn(let parkedDomains):
                guard !parkedDomains.isEmpty else { return }
                self?.navigationController?.popToRootViewController(animated: true)
            }
        })
    }
    
    func showQRScanner(selectedDomain: DomainDisplayInfo) {
        guard let navigationController = self.navigationController else { return }
        
        showQRScanner(in: navigationController,
                      selectedDomain: selectedDomain,
                      qrRecognizedCallback: { Task { await self.presenter?.didRecognizeQRCode() } })
    }
    
    func showDomainProfile(_ domain: DomainDisplayInfo,
                           wallet: UDWallet,
                           walletInfo: WalletDisplayInfo,
                           dismissCallback: EmptyCallback?) async {
        
        await showDomainProfileFromDomainsCollection(domain,
                                                     wallet: wallet,
                                                     walletInfo: walletInfo,
                                                     dismissCallback: { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.presenter?.viewDidAppear()
            }
            dismissCallback?()
        })
    }

    func isMintingAvailable(in viewController: UIViewController) async -> Bool {
        guard networkReachabilityService?.isReachable == true else {
            await appContext.pullUpViewService.showYouAreOfflinePullUp(in: viewController,
                                                                   unavailableFeature: .minting)
            return false
        }
        
        guard User.instance.getAppVersionInfo().mintingIsEnabled else {
            await appContext.pullUpViewService.showMintingNotAvailablePullUp(in: viewController)
            return false
        }
        
        return true
    }
    
    func runMintDomainsFlow(with mode: MintDomainsNavigationController.Mode) {
        Task {
            let domains = await dataAggregatorService.getDomainsDisplayInfo()
            
            let topPresentedViewController = navigationController?.topViewController
            if let mintingNav = topPresentedViewController as? MintDomainsNavigationController {
                mintingNav.setMode(mode)
            } else if let _ = topPresentedViewController as? AddWalletNavigationController {
                // MARK: - Ignore minting request when add/import/connect wallet
            } else if presenter?.isResolvingPrimaryDomain == false {
                await resetNavigationToRoot()
                guard let viewController = self.viewController,
                      await isMintingAvailable(in: viewController) else { return }
                
                let mintedDomains = domains.interactableItems()
                
                runMintDomainsFlow(with: mode,
                                   mintedDomains: mintedDomains,
                                   domainsMintedCallback: { [weak self] result in
                    self?.presenter?.didMintDomains(result: result)
                },
                                   in: viewController)
            }
        }
    }
    
    func showBuyDomainsWebView() {
        guard let viewController = self.viewController else { return }

        self.showBuyDomainsWebView(in: viewController) { [weak self] details in
            self?.runMintDomainsFlow(with: .domainsPurchased(details: details))
        }
    }
    
    func isTopPresented() -> Bool {
        viewController == topViewController()
    }
    
    func showAppUpdateRequired() {
        appContext.coreAppCoordinator.showAppUpdateRequired()
    }
    
    func showDomainsSearch(_ domains: [DomainDisplayInfo],
                           searchCallback: @escaping DomainsListSearchCallback) {
        guard let viewController = self.viewController else { return }

        self.showDomainsSearch(domains, searchCallback: searchCallback, in: viewController)
    }
    
    func showChatsListScreen() {
        Task { await showChatsListWith(options: .default) }
    }
    
    func showChat(_ chatId: String, profile: MessagingChatUserProfileDisplayInfo) async {
        await showChatsListWith(options: .showChat(chatId: chatId, profile: profile))
    }
    
    func showChannel(_ channelId: String, profile: MessagingChatUserProfileDisplayInfo) async {
        await showChatsListWith(options: .showChannel(channelId: channelId, profile: profile))
    }
}

// MARK: - Open methods
extension DomainsCollectionRouter {
    func topViewController() -> UIViewController? {
        navigationController?.topVisibleViewController()
    }

    @MainActor
    func showHomeScreenList() async {
        viewController?.loadViewIfNeeded()
        await resetNavigationToRoot()
    }
    
    @MainActor
    func primaryDomainMinted(_ domain: DomainDisplayInfo) async {
        if let mintingNav = navigationController?.topViewController?.presentedViewController as? MintDomainsNavigationController {
            mintingNav.refreshMintingProgress()
            Debugger.printWarning("Primary domain minted: Already on minting screen")
            return
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionRouter {
    @MainActor
    func resetNavigationToRoot() async {
        if let _ = navigationController?.presentedViewController {
            await navigationController?.dismiss(animated: true)
        }
        navigationController?.popToRootViewController(animated: false)
        await awaitUIUpdated()
    }
    
    @discardableResult
    func showDomainProfileFromDomainsCollection(_ domain: DomainDisplayInfo,
                                                wallet: UDWallet,
                                                walletInfo: WalletDisplayInfo,
                                                dismissCallback: EmptyCallback?) async -> CNavigationController? {
        guard let viewController = self.viewController else { return nil }
        
        defer {
            self.navigationController?.updateStatusBar()
        }
            
        func show(in viewToPresent: UIViewController) async -> CNavigationController? {
            await showDomainProfileScreen(in: viewToPresent, domain: domain, wallet: wallet, walletInfo: walletInfo, dismissCallback: dismissCallback)
        }
        
        navigationController?.popToRootViewController(animated: false)

        if let presentedViewController = viewController.presentedViewController {
            presentedViewController.view.endEditing(true)
            if let nav = presentedViewController as? EmptyRootCNavigationController,
               let presentedProfileVC = nav.viewControllers.first as? DomainProfileViewController,
               let presenter = presentedProfileVC.presenter as? DomainProfileViewPresenter {
                presenter.replace(domain: domain,
                                  wallet: wallet,
                                  walletInfo: walletInfo)
                nav.popToRootViewController(animated: true)
                if presentedProfileVC.presentedViewController != nil {
                    await presentedProfileVC.dismiss(animated: true)
                }
                return nav
            } else {
                if presentedViewController is UISearchController {
                    return await show(in: presentedViewController)
                } else {
                    await presentedViewController.dismiss(animated: true)
                    return await show(in: viewController)
                }
            }
        } else {
            return await show(in: viewController)
        }
    }
    
    func awaitUIUpdated() async {
        let interval: TimeInterval = 0.5
        let duration = UInt64(interval * 1_000_000_000)
        try? await Task.sleep(nanoseconds: duration)
    }
    
    func showChatsListWith(options: ChatsList.PresentOptions) async {
        guard let navigationController = self.navigationController else { return }
        
        if let presentedChatsList = navigationController.viewControllers.first(where: { $0 is ChatsListViewController } ) as? ChatsListViewController,
           let chatsListCoordinator = presentedChatsList.presenter as? ChatsListCoordinator {
            chatsListCoordinator.update(presentOptions: options)
        } else  {
            await resetNavigationToRoot()
            showChatsListScreen(in: navigationController, presentOptions: options)
        }
    }
}
