//
//  UDRouter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit
import SwiftUI

@MainActor
class UDRouter: DomainProfileSignatureValidator {
    func showWalletDetailsOf(wallet: WalletEntity,
                             source: WalletDetailsSource,
                             in viewController: UINavigationController) {
        let walletDetailsVC = UIHostingController(rootView: WalletDetailsView(wallet: wallet,
                                                                              source: source))
        viewController.pushViewController(walletDetailsVC, animated: true)
    }
    
    func showAddWalletScreenForAction(_ action: WalletDetailsAddWalletAction,
                                      in viewController: UIViewController,
                                      addedCallback: @escaping AddWalletNavigationController.WalletAddedCallback) {
        switch action {
        case .create:
            showCreateLocalWalletScreen(createdCallback: addedCallback, in: viewController)
        case .recoveryOrKey:
            showImportVerifiedWalletScreen(walletImportedCallback: addedCallback, in: viewController)
        case .connect:
            showConnectExternalWalletScreen(walletConnectedCallback: addedCallback, in: viewController)
        case .mpc:
            return
        }
    }
 
    func showCreateLocalWalletScreen(createdCallback: @escaping AddWalletNavigationController.WalletAddedCallback,
                                     in viewController: UIViewController) {
        showAddWalletScreen(with: .createLocal,
                            walletAddedCallback: createdCallback,
                            in: viewController)
    }
    
    func showImportVerifiedWalletScreen(walletImportedCallback: @escaping AddWalletNavigationController.WalletAddedCallback,
                                        in viewController: UIViewController) {
        showAddWalletScreen(with: .importExternal(walletType: .verified),
                            walletAddedCallback: walletImportedCallback,
                            in: viewController)
    }
    
    func showImportReadOnlyWalletScreen(walletImportedCallback: @escaping AddWalletNavigationController.WalletAddedCallback,
                                        in viewController: UIViewController) {
        showAddWalletScreen(with: .importExternal(walletType: .readOnly),
                            walletAddedCallback: walletImportedCallback,
                            in: viewController)
    }
    
    func showConnectExternalWalletScreen(walletConnectedCallback: @escaping AddWalletNavigationController.WalletAddedCallback,
                                        in viewController: UIViewController) {
        showAddWalletScreen(with: .connectExternal,
                            walletAddedCallback: walletConnectedCallback,
                            in: viewController)
    }
    
    func showRecoveryPhrase(of wallet: UDWallet,
                            recoveryType: UDWallet.RecoveryType,
                            in viewController: UIViewController,
                            dismissCallback: EmptyCallback?) {
        let revealVC = buildRevealRecoveryPhraseModule(for: wallet, recoveryType: recoveryType)
        presentInEmptyCRootNavigation(revealVC, in: viewController, dismissCallback: dismissCallback)
    }
    
    func showBackupWalletScreen(for wallet: UDWallet,
                                walletBackedUpCallback: @escaping WalletBackedUpCallback,
                                in viewController: UIViewController) {
        let vcToPresent: UIViewController
        if SecureHashStorage.retrievePassword() != nil {
            vcToPresent = buildEnterBackupToBackupWalletModule(for: wallet,
                                                               walletBackedUpCallback: walletBackedUpCallback)
        } else {
            vcToPresent = buildCreateBackupPasswordToBackupWalletModule(for: wallet,
                                                                        walletBackedUpCallback: walletBackedUpCallback)
        }
        presentInEmptyCRootNavigation(vcToPresent, in: viewController)
    }
    
    func showRestoreWalletsFromBackupScreen(for backup: UDWalletsService.WalletCluster,
                                            walletsRestoredCallback: @escaping WalletsRestoredCallback,
                                            in viewController: UIViewController) {
        let vc = buildEnterBackupToRestoreWalletsModule(for: backup,
                                                        walletsRestoredCallback: walletsRestoredCallback)
        presentInEmptyCRootNavigation(vc, in: viewController)
    }
    
    func showAppearanceSettingsScreen(in viewController: UINavigationController) {
        let vc = buildAppearanceSettingsModule()
        
        viewController.pushViewController(vc, animated: true)
    }
 
    @discardableResult
    func showDomainDetails(_ domain: DomainDisplayInfo,
                           in viewController: UIViewController) -> CNavigationController {
        let vc = buildDomainDetailsModule(domain: domain)
        let nav = CNavigationController(rootViewController: vc)
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .overFullScreen
        
        viewController.present(nav, animated: true)
        return nav
    }
    
    func showAddCurrency(from currencies: [CoinRecord],
                         excludedCurrencies: [CoinRecord],
                         addCurrencyCallback: @escaping AddCurrencyCallback,
                         in viewController: UIViewController) {
        let view = AddCurrencyView(currencies: currencies,
                                   excludedCurrencies: excludedCurrencies,
                                   addCurrencyCallback: { [weak viewController] currency in
            addCurrencyCallback(currency)
            viewController?.dismiss(animated: true, completion: nil)
        })
        let vc = UIHostingController(rootView: view)
        let nav = UINavigationController(rootViewController: vc)
        viewController.present(nav, animated: true)
    }
    
    func showManageMultiChainDomainAddresses(for records: [CryptoRecord],
                                             callback: @escaping ManageMultiChainDomainAddressesCallback,
                                             in viewController: UIViewController) {
        let vc = buildManageMultiChainDomainAddressesModule(records: records, callback: callback)
        vc.isModalInPresentation = true
        presentInEmptyRootNavigation(vc, in: viewController)
    }
    
    func runMintDomainsFlow(with mode: MintDomainsNavigationController.Mode,
                            mintedDomains: [DomainDisplayInfo],
                            domainsMintedCallback: @escaping MintDomainsNavigationController.DomainsMintedCallback,
                            in viewController: UIViewController) {
        showMintDomainsScreen(with: mode,
                              mintedDomains: mintedDomains,
                              domainsMintedCallback: domainsMintedCallback,
                              in: viewController)
    }
    
    func showWalletSelectionToMintDomainsScreen(in viewController: UIViewController,
                                                selectedWallet: WalletEntity?,
                                                selectionCallback: @escaping (WalletEntity)->()) {
        showProfileSelectionScreen(mode: .walletSelection(selectedWallet: selectedWallet,
                                                          selectionCallback: selectionCallback),
                                   in: viewController)
    }
    
    func showMintingDomainsInProgressScreen(mintingDomainsWithDisplayInfo: [MintingDomainWithDisplayInfo],
                                            mintingDomainSelectedCallback: MintingDomainSelectedCallback?,
                                            in viewController: UIViewController) {
        let vc = buildMintingDomainsInProgressModule(mintingDomainsWithDisplayInfo: mintingDomainsWithDisplayInfo,
                                                     mintingDomainSelectedCallback: mintingDomainSelectedCallback)
        
        presentInEmptyCRootNavigation(vc, in: viewController)
    }
    
    func showQRScanner(in viewController: CNavigationController,
                       selectedWallet: WalletEntity,
                       qrRecognizedCallback: @escaping EmptyAsyncCallback) {
        let vc = buildQRScannerModule(selectedWallet: selectedWallet,
                                      qrRecognizedCallback: qrRecognizedCallback)
        viewController.pushViewController(vc, animated: true)
    }

    func buildQRScannerModule(selectedWallet: WalletEntity,
                              qrRecognizedCallback: @escaping MainActorAsyncCallback) -> QRScannerViewController {
        let vc = QRScannerViewController.nibInstance()

        let presenter = QRScannerViewPresenter(view: vc,
                                               selectedWallet: selectedWallet,
                                               walletConnectServiceV2: appContext.walletConnectServiceV2,
                                               networkReachabilityService: appContext.networkReachabilityService,
                                               walletsDataService: appContext.walletsDataService)
        presenter.qrRecognizedCallback = qrRecognizedCallback
        vc.presenter = presenter
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
    
    func showProfileSelectionScreen(selectedWallet: WalletEntity,
                                    in viewController: UIViewController) {
        showProfileSelectionScreen(mode: .walletProfileSelection(selectedWallet: selectedWallet),
                                   in: viewController)
    }
    
    private func showProfileSelectionScreen(mode: UserProfileSelectionView.Mode,
                                            in viewController: UIViewController) {
        let vc = UserProfileSelectionView.viewController(mode: mode)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        viewController.present(vc, animated: true)
    }
    
    func showConnectedAppsListScreen(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation { completion in
            let vc = buildConnectedAppsModule()
            presentInEmptyCRootNavigation(vc, in: viewController, dismissCallback: { completion(Void()) })
        }
    }
    
    func buildConnectedAppsModule(scanCallback: EmptyCallback? = nil) -> UIViewController {
        let vc = ConnectedAppsListViewController.nibInstance()
        let presenter = ConnectedAppsListViewPresenter(view: vc,
                                                       walletConnectServiceV2: appContext.walletConnectServiceV2)
        presenter.scanCallback = scanCallback
        vc.presenter = presenter
        return vc
    }
    
    func showUpgradeToPolygonTutorialScreen(in viewController: UIViewController) {
        let vc = UpgradeToPolygonTutorial.nibInstance()
        
        presentInEmptyRootNavigation(vc, in: viewController)
    }
    
    func showBuyDomainsWebView(in viewController: UIViewController,
                               requireMintingCallback: @escaping PurchasedDomainsDetailsCallback) {
        let vc = BuyDomainsWebViewController()
        vc.requireMintingCallback = requireMintingCallback
        
        let nav = UINavigationController(rootViewController: vc)
        nav.isModalInPresentation = true
        viewController.present(nav, animated: true)
    }
    
    func showSetupChangeReverseResolutionModule(in viewController: UIViewController,
                                                wallet: WalletEntity,
                                                domain: DomainDisplayInfo,
                                                tabRouter: HomeTabRouter,
                                                resultCallback: @escaping MainActorAsyncCallback) {
        let view = ReverseResolutionSelectionView(wallet: wallet,
                                                  mode: .certain(domain),
                                                  domainSetCallback: { domain in
            resultCallback()
        })
            .environmentObject(tabRouter)
        let vc = UIHostingController(rootView: view)
        
        
        viewController.present(vc, animated: true)
    }
    
    func showReverseResolutionInProgressScreen(in viewController: UIViewController,
                                               domain: DomainItem,
                                               domainDisplayInfo: DomainDisplayInfo,
                                               walletInfo: WalletDisplayInfo) {
        let vc = buildReverseResolutionInProgressModule(domain: domain,
                                                        domainDisplayInfo: domainDisplayInfo,
                                                        walletInfo: walletInfo)
        
        presentInEmptyCRootNavigation(vc, in: viewController)
    }
    
    func buildDomainProfileModule(domain: DomainDisplayInfo,
                                  wallet: WalletEntity,
                                  preRequestedAction: PreRequestedProfileAction?,
                                  sourceScreen: DomainProfileViewPresenter.SourceScreen,
                                  tabRouter: HomeTabRouter) -> UIViewController {
        let vc = DomainProfileViewController.nibInstance()
        let presenter = DomainProfileViewPresenter(view: vc,
                                                   domain: domain,
                                                   wallet: wallet,
                                                   preRequestedAction: preRequestedAction,
                                                   sourceScreen: sourceScreen,
                                                   tabRouter: tabRouter,
                                                   walletsDataService: appContext.walletsDataService,
                                                   domainRecordsService: appContext.domainRecordsService,
                                                   domainTransactionsService: appContext.domainTransactionsService,
                                                   coinRecordsService: appContext.coinRecordsService,
                                                   externalEventsService: appContext.externalEventsService)
        vc.presenter = presenter
        return vc
    }
    
    private func prepareProfileScreen(in viewToPresent: UIViewController,
                                      domain: DomainDisplayInfo,
                                      walletInfo: WalletDisplayInfo) async -> Bool {
        guard await isProfileSignatureAvailable(for: domain,
                                                walletInfo: walletInfo,
                                                in: viewToPresent) else { return false }
        
        if !UserDefaults.didShowDomainProfileInfoTutorial {
            UserDefaults.didShowDomainProfileInfoTutorial = true
            await UDRouter().showDomainProfileTutorial(in: viewToPresent)
        }
        return true
    }
    
    func showEnterEmailValueModule(in nav: UINavigationController,
                                    email: String?,
                                    enteredEmailValueCallback: @escaping EnterEmailValueCallback) {
        let vc = UIHostingController(rootView: EnterDomainEmailView(email: email ?? "",
                                                                    enteredEmailValueCallback: enteredEmailValueCallback))
        
        nav.pushViewController(vc, animated: true)
    }
    
    func showDomainProfileFetchFailedModule(in viewController: UIViewController,
                                            domain: DomainDisplayInfo,
                                            imagesInfo: DomainProfileActionCoverViewPresenter.DomainImagesInfo) async throws {
        try await withSafeCheckedThrowingMainActorContinuation { completion in
            let vc = buildDomainProfileFetchFailedModule(domain: domain,
                                                         imagesInfo: imagesInfo,
                                                         refreshActionCallback: { [weak viewController] result in
                switch result {
                case .refresh:
                    viewController?.dismiss(animated: true, completion: {
                        completion(.success(Void()))
                    })
                case .close:
                    viewController?.presentingViewController?.dismiss(animated: true, completion: {
                        completion(.failure(UDRouterError.dismissed))
                    })
                }
            })
            let nav = presentInEmptyCRootNavigation(vc, in: viewController)
            nav.isModalInPresentation = true
        }
    }
    
    func showDomainProfileSignExternalWalletModule(in viewController: UIViewController,
                                                   domain: DomainDisplayInfo,
                                                   imagesInfo: DomainProfileActionCoverViewPresenter.DomainImagesInfo,
                                                   externalWallet: WalletDisplayInfo) -> AsyncStream<DomainProfileSignExternalWalletViewPresenter.ResultAction> {
        AsyncStream { continuation in
            let vc = buildDomainProfileSignExternalWalletModule(domain: domain,
                                                                imagesInfo: imagesInfo,
                                                                externalWallet: externalWallet,
                                                                refreshActionCallback: { result in
                continuation.yield(result)
            })
            let nav = presentInEmptyCRootNavigation(vc, in: viewController)
            nav.isModalInPresentation = true
        }
    }
    
    func showImportExistingExternalWalletModule(in viewController: UIViewController,
                                                externalWalletInfo: WalletDisplayInfo,
                                                walletImportedCallback: @escaping ImportExistingExternalWalletPresenter.WalletImportedCallback) {
        let vc = buildImportExistingExternalWalletModule(externalWalletInfo: externalWalletInfo,
                                                         walletImportedCallback: walletImportedCallback)
        
        let nav = presentInEmptyCRootNavigation(vc, in: viewController)
        nav.isModalInPresentation = true
    }
    
    func showDomainImageDetails(_ domain: DomainDisplayInfo,
                                imageState: DomainProfileTopInfoData.ImageState,
                                in viewController: UIViewController) {
        let vc = buildDomainImageDetailsModule(domain: domain,
                                               imageState: imageState)
        let nav = CNavigationController(rootViewController: vc)
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .overFullScreen
        
        viewController.present(nav, animated: true)
    }
    
    func showDomainProfileTutorial(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation { completion in
            let vc = DomainProfileTutorialViewController.nibInstance()
            vc.completionCallback = {
                completion(Void())
            }
            vc.isModalInPresentation = true
            viewController.present(vc, animated: true)
        }
    }
    
    func runLoginFlow(with mode: LoginFlowNavigationController.Mode,
                      loggedInCallback: @escaping LoginFlowNavigationController.LoggedInCallback,
                      in viewController: UIViewController) {
        showLoginScreen(with: mode, loggedInCallback: loggedInCallback, in: viewController)
    }
    
    func showDomainProfileParkedActionModule(in viewController: UIViewController,
                                             domain: DomainDisplayInfo,
                                             imagesInfo: DomainProfileActionCoverViewPresenter.DomainImagesInfo) async -> DomainProfileParkedAction {
        await withSafeCheckedMainActorContinuation { completion in
            let vc = buildDomainProfileParkedModule(domain: domain,
                                                    imagesInfo: imagesInfo,
                                                    refreshActionCallback: { [weak viewController] result in
                viewController?.dismiss(animated: true, completion: {
                    completion(result)
                })
            })
            let nav = presentInEmptyCRootNavigation(vc, in: viewController)
            nav.isModalInPresentation = true
        }
    }
    
    func showTransferInProgressScreen(domain: DomainDisplayInfo,
                                      in viewController: UIViewController) {
        let vc = buildTransferInProgressModule(domain: domain)
        
        presentInEmptyCRootNavigation(vc, in: viewController)
    }
    
    private func buildTransferInProgressModule(domain: DomainDisplayInfo) -> UIViewController {
        let vc = TransactionInProgressViewController.nibInstance()
        let presenter = TransferDomainTransactionInProgressViewPresenter(view: vc,
                                                                         domainDisplayInfo: domain,
                                                                         transactionsService: appContext.domainTransactionsService,
                                                                         notificationsService: appContext.notificationsService)
        
        vc.presenter = presenter
        return vc
    }
    
    func showPublicDomainProfile(of domain: PublicDomainDisplayInfo,
                                 by wallet: WalletEntity?,
                                 preRequestedAction: PreRequestedProfileAction? = nil,
                                 in viewController: UIViewController) {
        let vc = PublicProfileView.instantiate(configuration: PublicProfileViewConfiguration(domain: domain,
                                                                                             viewingWallet: wallet,
                                                                                             preRequestedAction: preRequestedAction,
                                                                                             delegate: viewController))
        viewController.present(vc, animated: true)
    }
    
    func showFollowersList(domainName: DomainName,
                           socialInfo: DomainProfileSocialInfo,
                           followerSelectionCallback: @escaping FollowerSelectionCallback,
                           in viewController: UIViewController) {
        let vc = PublicProfileFollowersView.instantiate(domainName: domainName,
                                                        socialInfo: socialInfo,
                                                        followerSelectionCallback: followerSelectionCallback)
        viewController.present(vc, animated: true)
    }
    
    func showHotFeatureSuggestionDetails(suggestion: HotFeatureSuggestion,
                                         in viewController: UIViewController) {
        let view = HotFeatureSuggestionDetailsView(suggestion: suggestion)
        let vc = UIHostingController(rootView: view)
        viewController.present(vc, animated: true)
    }
    
    func showActivateMPCWalletScreen(activationResultCallback: @escaping ActivateMPCWalletFlow.FlowResultCallback,
                                     in viewController: UIViewController) {
        let view = ActivateMPCWalletRootView(activationResultCallback: activationResultCallback)
        let vc = UIHostingController(rootView: view)
        viewController.present(vc, animated: true)
    }
}

// MARK: - Private methods
private extension UDRouter {
    func presentInEmptyRootNavigation(_ rootViewController: UIViewController,
                                      in viewController: UIViewController,
                                      dismissCallback: EmptyCallback? = nil) {
        let emptyRootNav = EmptyRootNavigationController(rootViewController: rootViewController)
        emptyRootNav.dismissCallback = dismissCallback
        viewController.present(emptyRootNav, animated: true)
    }
    
    @discardableResult
    func presentInEmptyCRootNavigation(_ rootViewController: UIViewController,
                                      in viewController: UIViewController,
                                      dismissCallback: EmptyCallback? = nil) -> EmptyRootCNavigationController {
        let emptyRootNav = EmptyRootCNavigationController(rootViewController: rootViewController)
        emptyRootNav.dismissCallback = dismissCallback
        viewController.present(emptyRootNav, animated: true)
        return emptyRootNav
    }
    
    func showAddWalletScreen(with mode: AddWalletNavigationController.Mode,
                             walletAddedCallback: @escaping AddWalletNavigationController.WalletAddedCallback,
                             in viewController: UIViewController) {
        let createWalletNavigationController = AddWalletNavigationController(mode: mode)
        createWalletNavigationController.walletAddedCallback = walletAddedCallback
        
        viewController.present(createWalletNavigationController, animated: true)
    }
    
    func showMintDomainsScreen(with mode: MintDomainsNavigationController.Mode,
                               mintedDomains: [DomainDisplayInfo],
                               domainsMintedCallback: @escaping MintDomainsNavigationController.DomainsMintedCallback,
                               in viewController: UIViewController) {
        let mintDomainsNavigationController = MintDomainsNavigationController(mode: mode, mintedDomains: mintedDomains)
        mintDomainsNavigationController.domainsMintedCallback = domainsMintedCallback
        viewController.cNavigationController?.pushViewController(mintDomainsNavigationController,
                                                                animated: true)
    }
    
    func showLoginScreen(with mode: LoginFlowNavigationController.Mode,
                         loggedInCallback: @escaping LoginFlowNavigationController.LoggedInCallback,
                         in viewController: UIViewController) {
        let mintDomainsNavigationController = LoginFlowNavigationController(mode: mode)
        mintDomainsNavigationController.loggedInCallback = loggedInCallback
        viewController.cNavigationController?.pushViewController(mintDomainsNavigationController,
                                                                 animated: true)
    }
}

// MARK: - Build methods
private extension UDRouter {
    func buildRevealRecoveryPhraseModule(for wallet: UDWallet,
                                         recoveryType: UDWallet.RecoveryType) -> UIViewController {
        let vc = RecoveryPhraseViewController.nibInstance()
        let presenter = RevealRecoveryPhrasePresenter(view: vc,
                                                      recoveryType: recoveryType,
                                                      wallet: wallet)
        vc.presenter = presenter
        
        return vc
    }
    
    func buildCreateBackupPasswordToBackupWalletModule(for wallet: UDWallet, walletBackedUpCallback: @escaping WalletBackedUpCallback) -> UIViewController {
        let vc = CreatePasswordViewController.nibInstance()
        let presenter = CreateBackupPasswordToBackupWalletPresenter(view: vc,
                                                                    wallet: wallet,
                                                                    udWalletsService: appContext.udWalletsService,
                                                                    walletBackedUpCallback: walletBackedUpCallback)
        vc.presenter = presenter
        
        return vc
    }
    
    func buildEnterBackupToBackupWalletModule(for wallet: UDWallet, walletBackedUpCallback: @escaping WalletBackedUpCallback) -> UIViewController {
        let vc = EnterBackupViewController.nibInstance()
        let presenter = EnterBackupToBackupWalletPresenter(view: vc,
                                                           wallet: wallet,
                                                           udWalletsService: appContext.udWalletsService,
                                                           walletBackedUpCallback: walletBackedUpCallback)
        vc.presenter = presenter
        
        return vc
    }
    
    func buildEnterBackupToRestoreWalletsModule(for backup: UDWalletsService.WalletCluster, walletsRestoredCallback: @escaping WalletsRestoredCallback) -> UIViewController {
        let vc = EnterBackupViewController.nibInstance()
        let presenter = EnterBackupToRestoreWalletsPresenter(view: vc,
                                                             backup: backup,
                                                             udWalletsService: appContext.udWalletsService,
                                                             walletsRestoredCallback: walletsRestoredCallback)
        vc.presenter = presenter
        
        return vc
    }
    
    func buildAppearanceSettingsModule() -> UIViewController {
        let vc = AppearanceSettingsViewController.nibInstance()
        let presenter = AppearanceSettingsViewPresenter(view: vc)
        vc.presenter = presenter
        return vc
    }
    
    func buildDomainDetailsModule(domain: DomainDisplayInfo) -> UIViewController {
        let vc = DomainDetailsViewController.nibInstance()
        let presenter = DomainDetailsViewPresenter(view: vc,
                                                      domain: domain)
        vc.presenter = presenter
        return vc
    }
    
    func buildAddCurrencyModule(currencies: [CoinRecord],
                                excludedCurrencies: [CoinRecord],
                                addCurrencyCallback: @escaping AddCurrencyCallback) -> UIViewController {
        let vc = AddCurrencyViewController.nibInstance()
        let presenter = AddCurrencyViewPresenter(view: vc,
                                                 currencies: currencies,
                                                 excludedCurrencies: excludedCurrencies,
                                                 coinRecordsService: appContext.coinRecordsService,
                                                 addCurrencyCallback: addCurrencyCallback)
        vc.presenter = presenter
        return vc
    }
    
    func buildManageMultiChainDomainAddressesModule(records: [CryptoRecord],
                                                    callback: @escaping ManageMultiChainDomainAddressesCallback) -> UIViewController {
        let vc = ManageMultiChainDomainAddressesViewController.nibInstance()
        let presenter = ManageMultiChainDomainAddressesViewPresenter(view: vc,
                                                                     records: records,
                                                                     callback: callback)
        vc.presenter = presenter
        return vc
    }
   
    func buildMintingDomainsInProgressModule(mintingDomainsWithDisplayInfo: [MintingDomainWithDisplayInfo],
                                             mintingDomainSelectedCallback: MintingDomainSelectedCallback?) -> UIViewController {
        let vc = TransactionInProgressViewController.nibInstance()
        let presenter = MintingNotPrimaryDomainsInProgressViewPresenter(view: vc,
                                                                        mintingDomainsWithDisplayInfo: mintingDomainsWithDisplayInfo,
                                                                        mintingDomainSelectedCallback: mintingDomainSelectedCallback,
                                                                        transactionsService: appContext.domainTransactionsService,
                                                                        notificationsService: appContext.notificationsService)
        vc.presenter = presenter
        return vc
    }
    
    func buildReverseResolutionInProgressModule(domain: DomainItem,
                                                domainDisplayInfo: DomainDisplayInfo,
                                                walletInfo: WalletDisplayInfo) -> UIViewController {
        let vc = TransactionInProgressViewController.nibInstance()
        let presenter = ReverseResolutionTransactionInProgressViewPresenter(view: vc,
                                                                            domain: domain,
                                                                            domainDisplayInfo: domainDisplayInfo,
                                                                            walletInfo: walletInfo,
                                                                            transactionsService: appContext.domainTransactionsService,
                                                                            notificationsService: appContext.notificationsService)
        vc.presenter = presenter
        return vc
    }
    
    func buildDomainProfileFetchFailedModule(domain: DomainDisplayInfo,
                                             imagesInfo: DomainProfileActionCoverViewPresenter.DomainImagesInfo,
                                             refreshActionCallback: @escaping DomainProfileFetchFailedActionCallback) -> UIViewController {
        let vc = DomainProfileActionCoverViewController.nibInstance()
        let presenter = DomainProfileFetchFailedActionCoverViewPresenter(view: vc,
                                                                         domain: domain,
                                                                         imagesInfo: imagesInfo,
                                                                         refreshActionCallback: refreshActionCallback)
        vc.presenter = presenter
        return vc
    }
    
    func buildDomainProfileSignExternalWalletModule(domain: DomainDisplayInfo,
                                                    imagesInfo: DomainProfileActionCoverViewPresenter.DomainImagesInfo,
                                                    externalWallet: WalletDisplayInfo,
                                                    refreshActionCallback: @escaping DomainProfileSignExternalWalletActionCallback) -> UIViewController {
        let vc = DomainProfileActionCoverViewController.nibInstance()
        let presenter = DomainProfileSignExternalWalletViewPresenter(view: vc,
                                                                     domain: domain,
                                                                     imagesInfo: imagesInfo,
                                                                     externalWallet: externalWallet,
                                                                     refreshActionCallback: refreshActionCallback)
        vc.presenter = presenter
        return vc
    }
    
    
    func buildImportExistingExternalWalletModule(externalWalletInfo: WalletDisplayInfo,
                                                 walletImportedCallback: @escaping ImportExistingExternalWalletPresenter.WalletImportedCallback) -> UIViewController {
        let vc = AddWalletViewController.nibInstance()
        let presenter = ImportExistingExternalWalletPresenter(view: vc,
                                                              walletType: .verified,
                                                              udWalletsService: appContext.udWalletsService,
                                                              externalWalletInfo: externalWalletInfo,
                                                              walletImportedCallback: walletImportedCallback)
        vc.presenter = presenter
        return vc
    }
    
    func buildDomainImageDetailsModule(domain: DomainDisplayInfo,
                                       imageState: DomainProfileTopInfoData.ImageState) -> UIViewController {
        let vc = DomainDetailsViewController.nibInstance()
        let presenter = DomainImageDetailsViewPresenter(view: vc,
                                                        domain: domain,
                                                        imageState: imageState)
        vc.presenter = presenter
        return vc
    }
    
    func buildDomainProfileParkedModule(domain: DomainDisplayInfo,
                                        imagesInfo: DomainProfileActionCoverViewPresenter.DomainImagesInfo,
                                        refreshActionCallback: @escaping DomainProfileParkedActionCallback) -> UIViewController {
        let vc = DomainProfileActionCoverViewController.nibInstance()
        let presenter = DomainProfileParkedActionCoverViewPresenter(view: vc,
                                                                    domain: domain,
                                                                    imagesInfo: imagesInfo,
                                                                    refreshActionCallback: refreshActionCallback)
        vc.presenter = presenter
        return vc
    }
    
//    func buildChatRequestsModuleWith(dataType: ChatsRequestsListViewPresenter.DataType,
//                                     profile: MessagingChatUserProfileDisplayInfo) -> UIViewController {
//        let vc = ChatsListViewController.nibInstance()
//        let presenter = ChatsRequestsListViewPresenter(view: vc,
//                                                       dataType: dataType,
//                                                       profile: profile)
//        vc.presenter = presenter
//        return vc
//    }
//    
//    func buildChatModule(profile: MessagingChatUserProfileDisplayInfo,
//                         conversationState: MessagingChatConversationState) -> UIViewController {
//        let vc = ChatViewController.nibInstance()
//        vc.hidesBottomBarWhenPushed = true
//        let presenter = ChatViewPresenter(view: vc,
//                                          profile: profile,
//                                          conversationState: conversationState,
//                                          messagingService: appContext.messagingService, 
//                                          featureFlagsService: appContext.udFeatureFlagsService)
//        vc.presenter = presenter
//        return vc
//    }
//    
//    func buildChannelModule(profile: MessagingChatUserProfileDisplayInfo,
//                            channel: MessagingNewsChannel) -> UIViewController {
//        let vc = ChatViewController.nibInstance()
//        vc.hidesBottomBarWhenPushed = true
//        let presenter = ChannelViewPresenter(view: vc,
//                                             profile: profile,
//                                             channel: channel)
//        vc.presenter = presenter
//        return vc
//    }
}

extension UDRouter {
    enum WalletDetailsSource {
        case settings
        case domainDetails(domainChangeCallback: (DomainDisplayInfo)->())
    }
    
    enum UDRouterError: Error {
        case dismissed
    }
}
