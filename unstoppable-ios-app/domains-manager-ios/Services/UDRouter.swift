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
    func showSettings(in viewController: CNavigationController,
                      loginCallback: LoginFlowNavigationController.LoggedInCallback?) {
        let settingsVC = buildSettingsModule(loginCallback: loginCallback)
        viewController.pushViewController(settingsVC, animated: true)
    }
    
    func buildSettingsModule(loginCallback: LoginFlowNavigationController.LoggedInCallback?) -> UIViewController {
        let vc = SettingsViewController.nibInstance()
        let presenter = SettingsPresenter(view: vc,
                                          loginCallback: loginCallback,
                                          notificationsService: appContext.notificationsService,
                                          firebaseAuthenticationService: appContext.firebaseParkedDomainsAuthenticationService)
        vc.presenter = presenter
        
        return vc
    }
    
    func showWalletsList(in viewController: CNavigationController, initialAction: WalletsListViewPresenter.InitialAction) {
        let walletsListVC = buildWalletsListModule(initialAction: initialAction)
        viewController.pushViewController(walletsListVC, animated: true)
    }
    
    func buildWalletsListModule(initialAction: WalletsListViewPresenter.InitialAction) -> UIViewController {
        let vc = WalletsListViewController.nibInstance()
        let presenter = WalletsListViewPresenter(view: vc,
                                                 initialAction: initialAction,
                                                 networkReachabilityService: appContext.networkReachabilityService,
                                                 udWalletsService: appContext.udWalletsService)
        vc.presenter = presenter
        
        return vc
    }
    
    func showWalletDetailsOf(wallet: WalletEntity,
                             source: WalletDetailsSource,
                             in viewController: CNavigationController) {
        let walletDetailsVC = buildWalletDetailsModuleFor(wallet: wallet, walletRemovedCallback: { [weak viewController] in
            switch source {
            case .walletsList:
                viewController?.popViewController(animated: true)
            case .domainDetails, .domainsCollection:
                viewController?.dismiss(animated: true)
            }
        })
        
        switch source {
        case .walletsList, .domainDetails:
            viewController.pushViewController(walletDetailsVC, animated: true)
        case .domainsCollection:
            walletDetailsVC.currentNavBackStyle = .cancel
            presentInEmptyCRootNavigation(walletDetailsVC, in: viewController)
        }
    }
    
    func buildWalletDetailsModuleFor(wallet: WalletEntity, walletRemovedCallback: EmptyCallback?) -> WalletDetailsViewController {
        let vc = WalletDetailsViewController.nibInstance()
        let presenter = WalletDetailsViewPresenter(view: vc,
                                                   wallet: wallet,
                                                   networkReachabilityService: appContext.networkReachabilityService,
                                                   udWalletsService: appContext.udWalletsService,
                                                   walletConnectServiceV2: appContext.walletConnectServiceV2)
        presenter.walletRemovedCallback = walletRemovedCallback
        vc.presenter = presenter
        
        return vc
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
    
    func showRenameWalletScreen(of wallet: UDWallet,
                                walletDisplayInfo: WalletDisplayInfo,
                                nameUpdatedCallback: @escaping RenameWalletViewPresenter.WalletNameUpdatedCallback,
                                in viewController: UIViewController) {
        let renameDetailsVC = buildRenameWalletModuleFor(wallet: wallet, walletDisplayInfo: walletDisplayInfo, nameUpdatedCallback: nameUpdatedCallback)
        presentInEmptyCRootNavigation(renameDetailsVC, in: viewController)
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
    
    func showSecuritySettingsScreen(in viewController: CNavigationController) {
        let vc = buildSecuritySettingsModule()
        
        viewController.pushViewController(vc, animated: true)
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
        let vc = buildAddCurrencyModule(currencies: currencies, excludedCurrencies: excludedCurrencies, addCurrencyCallback: addCurrencyCallback)
        vc.isModalInPresentation = true
        presentInEmptyRootNavigation(vc, in: viewController)
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
    
    func runTransferDomainFlow(with mode: TransferDomainNavigationManager.Mode,
                               transferResultCallback: @escaping TransferDomainNavigationManager.TransferResultCallback,
                               in viewController: UIViewController) {
        let mintDomainsNavigationController = TransferDomainNavigationManager(mode: mode)
        mintDomainsNavigationController.modalPresentationStyle = .fullScreen
        mintDomainsNavigationController.transferResultCallback = transferResultCallback
        viewController.present(mintDomainsNavigationController, animated: true)
    }
    
    func showWalletSelectionToMintDomainsScreen(selectedWallet: WalletEntity?,
                                                in viewController: UIViewController) async throws -> WalletEntity {
        try await withSafeCheckedThrowingMainActorContinuation { completion in
            let vc = buildSelectWalletToMintModule(selectedWallet: selectedWallet,
                                                   walletSelectedCallback: { wallet in
                completion(.success(wallet))
            })
            
            presentInEmptyCRootNavigation(vc, in: viewController, dismissCallback: { completion(.failure(UDRouterError.dismissed)) })
        }
    }
    
    func showMintingDomainsInProgressScreen(mintingDomainsWithDisplayInfo: [MintingDomainWithDisplayInfo],
                                            mintingDomainSelectedCallback: MintingDomainSelectedCallback?,
                                            in viewController: UIViewController) {
        let vc = buildMintingDomainsInProgressModule(mintingDomainsWithDisplayInfo: mintingDomainsWithDisplayInfo,
                                                     mintingDomainSelectedCallback: mintingDomainSelectedCallback)
        
        presentInEmptyCRootNavigation(vc, in: viewController)
    }
    
    func showWalletDomains(wallet: WalletEntity,
                           in viewController: UIViewController) {
        let vc = buildWalletDomainsListModule(wallet: wallet)
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
        let vc = UserProfileSelectionView.viewController(mode: .walletProfileSelection(selectedWallet: selectedWallet))
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
    
    func showSetupNewReverseResolutionModule(in nav: CNavigationController,
                                             wallet: WalletEntity,
                                             domains: [DomainDisplayInfo],
                                             reverseResolutionDomain: DomainDisplayInfo,
                                             resultCallback: @escaping DomainItemSelectedCallback) {
        let vc = buildSetupReverseResolutionModule(wallet: wallet,
                                                   domains: domains,
                                                   reverseResolutionDomain: reverseResolutionDomain,
                                                   resultCallback: resultCallback)
        
        nav.pushViewController(vc, animated: true)
    }
    
    func showSetupChangeReverseResolutionModule(in viewController: UIViewController,
                                                wallet: WalletEntity,
                                                domain: DomainDisplayInfo,
                                                resultCallback: @escaping MainActorAsyncCallback) {
        let vc = buildSetupChangeReverseResolutionModule(wallet: wallet,
                                                         domain: domain,
                                                         resultCallback: resultCallback)
        
        presentInEmptyCRootNavigation(vc, in: viewController)
    }
    
    func runSetupReverseResolutionFlow(in viewController: UIViewController,
                                       for wallet: WalletEntity,
                                       mode: SetupWalletsReverseResolutionNavigationManager.Mode) async -> SetupWalletsReverseResolutionNavigationManager.Result {
        await withSafeCheckedMainActorContinuation { completion in
            let vc = buildSetupReverseResolutionFlowModule(mode: mode,
                                                           wallet: wallet) { result in
                completion(result)
            }
            
            viewController.present(vc, animated: true)
        }
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
    
    @discardableResult
    func showDomainProfileScreen(in viewController: UIViewController,
                                 domain: DomainDisplayInfo,
                                 wallet: WalletEntity,
                                 preRequestedAction: PreRequestedProfileAction?,
                                 dismissCallback: EmptyCallback?) async -> CNavigationController? {
        guard await prepareProfileScreen(in: viewController, domain: domain, walletInfo: wallet.displayInfo) else { return nil }
        let vc = buildDomainProfileModule(domain: domain,
                                          wallet: wallet,
                                          preRequestedAction: preRequestedAction,
                                          sourceScreen: .domainsCollection)

        let nav = presentInEmptyCRootNavigation(vc,
                                                in: viewController,
                                                dismissCallback: dismissCallback)
        nav.isModalInPresentation = true
        
        return nav
    }
    
    func pushDomainProfileScreen(in nav: CNavigationController,
                                 domain: DomainDisplayInfo,
                                 wallet: WalletEntity,
                                 preRequestedAction: PreRequestedProfileAction?) async {
        guard await prepareProfileScreen(in: nav, domain: domain, walletInfo: wallet.displayInfo) else { return }

        let vc = buildDomainProfileModule(domain: domain,
                                          wallet: wallet,
                                          preRequestedAction: preRequestedAction,
                                          sourceScreen: .domainsList)
        nav.pushViewController(vc, animated: true)
    }
    
    func buildDomainProfileModule(domain: DomainDisplayInfo,
                                  wallet: WalletEntity,
                                  preRequestedAction: PreRequestedProfileAction?,
                                  sourceScreen: DomainProfileViewPresenter.SourceScreen) -> UIViewController {
        let vc = DomainProfileViewController.nibInstance()
        let presenter = DomainProfileViewPresenter(view: vc,
                                                   domain: domain,
                                                   wallet: wallet,
                                                   preRequestedAction: preRequestedAction,
                                                   sourceScreen: sourceScreen,
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
    
    func runAddSocialsFlow(with mode: DomainProfileAddSocialNavigationController.Mode,
                           socialType: SocialsType,
                           socialVerifiedCallback: @escaping DomainProfileAddSocialNavigationController.SocialVerifiedCallback,
                           in viewController: CNavigationController) {
        let mintDomainsNavigationController = DomainProfileAddSocialNavigationController(mode: mode, socialType: socialType)
        mintDomainsNavigationController.socialVerifiedCallback = socialVerifiedCallback
        viewController.pushViewController(mintDomainsNavigationController,
                                          animated: true)
        mintDomainsNavigationController.navigationBar.isModalInPageSheet = viewController.navigationBar.isModalInPageSheet
    }
    
    func showEnterEmailValueModule(in nav: CNavigationController,
                                    email: String?,
                                    enteredEmailValueCallback: @escaping EnterEmailValueCallback) {
        let vc = buildEnterEmailValueModule(email: email,
                                            enteredEmailValueCallback: enteredEmailValueCallback)
        
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
                                      transferDomainFlowManager: TransferDomainFlowManager?,
                                      in viewController: UIViewController) {
        let vc = buildTransferInProgressModule(domain: domain,
                                               transferDomainFlowManager: transferDomainFlowManager)
        
        presentInEmptyCRootNavigation(vc, in: viewController)
    }
    
    func buildTransferInProgressModule(domain: DomainDisplayInfo,
                                       transferDomainFlowManager: TransferDomainFlowManager?) -> UIViewController {
        let vc = TransactionInProgressViewController.nibInstance()
        let presenter = TransferDomainTransactionInProgressViewPresenter(view: vc,
                                                                         domainDisplayInfo: domain,
                                                                         transactionsService: appContext.domainTransactionsService,
                                                                         notificationsService: appContext.notificationsService,
                                                                         transferDomainFlowManager: transferDomainFlowManager)
        
        vc.presenter = presenter
        return vc
    }
    
    func showInviteFriendsScreen(domain: DomainItem,
                                 in nav: CNavigationController) {
        let vc = buildInviteFriendsModule(domain: domain)
        
        nav.pushViewController(vc, animated: true)
    }
    
//    func showChatsListScreen(in nav: CNavigationController,
//                             presentOptions: ChatsList.PresentOptions) {
//        let vc = buildChatsListModule(presentOptions: presentOptions)
//        
//        nav.pushViewController(vc, animated: true)
//    }
    
//    func buildChatsListModule(presentOptions: ChatsList.PresentOptions) -> ChatsListViewController {
//        let vc = ChatsListViewController.nibInstance()
//        let walletsService = appContext.walletsDataService
//        let presenter = ChatsListViewPresenter(view: vc,
//                                               presentOptions: presentOptions, 
//                                               selectedWallet: walletsService.selectedWallet,
//                                               messagingService: appContext.messagingService)
//        vc.presenter = presenter
//        return vc
//    }
//    
//    func showChatRequestsScreen(dataType: ChatsRequestsListViewPresenter.DataType,
//                                profile: MessagingChatUserProfileDisplayInfo,
//                                in nav: CNavigationController) {
//        let vc = buildChatRequestsModuleWith(dataType: dataType,
//                                             profile: profile)
//        
//        nav.pushViewController(vc, animated: true)
//    }
    
//    func showChatScreen(profile: MessagingChatUserProfileDisplayInfo,
//                        conversationState: MessagingChatConversationState,
//                        in nav: CNavigationController) {
//        let vc = buildChatModule(profile: profile,
//                                 conversationState: conversationState)
//        
//        nav.pushViewController(vc, animated: true)
//    }
//    
//    func showChannelScreen(profile: MessagingChatUserProfileDisplayInfo,
//                           channel: MessagingNewsChannel,
//                           in nav: CNavigationController) {
//        let vc = buildChannelModule(profile: profile,
//                                    channel: channel)
//        
//        nav.pushViewController(vc, animated: true)
//    }
    
    func showPublicDomainProfile(of domain: PublicDomainDisplayInfo,
                                 by wallet: WalletEntity,
                                 viewingDomain: DomainDisplayInfo?,
                                 preRequestedAction: PreRequestedProfileAction?,
                                 in viewController: UIViewController) {
        let vc = PublicProfileView.instantiate(domain: domain,
                                               wallet: wallet,
                                               viewingDomain: viewingDomain,
                                               preRequestedAction: preRequestedAction,
                                               delegate: viewController)
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
    
    func buildRenameWalletModuleFor(wallet: UDWallet, walletDisplayInfo: WalletDisplayInfo, nameUpdatedCallback: @escaping RenameWalletViewPresenter.WalletNameUpdatedCallback) -> UIViewController {
        
        let vc = RenameWalletViewController.nibInstance()
        let presenter = RenameWalletViewPresenter(view: vc,
                                                  wallet: wallet,
                                                  walletDisplayInfo: walletDisplayInfo,
                                                  udWalletsService: appContext.udWalletsService,
                                                  nameUpdatedCallback: nameUpdatedCallback)
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
    
    func buildSecuritySettingsModule() -> UIViewController {
        let vc = SecuritySettingsViewController.nibInstance()
        let presenter = SecuritySettingsViewPresenter(view: vc)
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
    
    func buildSelectWalletToMintModule(selectedWallet: WalletEntity?, walletSelectedCallback: @escaping WalletSelectedCallback) -> UIViewController {
        let vc = WalletsListViewController.nibInstance()
        let presenter = WalletListSelectionToMintDomainsPresenter(view: vc,
                                                                  udWalletsService: appContext.udWalletsService,
                                                                  selectedWallet: selectedWallet,
                                                                  networkReachabilityService: appContext.networkReachabilityService,
                                                                  walletSelectedCallback: walletSelectedCallback)
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
    
    func buildWalletDomainsListModule(wallet: WalletEntity) -> UIViewController {
        let vc = DomainsListViewController.nibInstance()
        let presenter = DomainsListPresenter(view: vc,
                                             wallet: wallet)
        vc.presenter = presenter
        return vc
    }
    
    func buildSetupReverseResolutionModule(wallet: WalletEntity,
                                           domains: [DomainDisplayInfo],
                                           reverseResolutionDomain: DomainDisplayInfo,
                                           resultCallback: @escaping DomainItemSelectedCallback) -> UIViewController {
        let vc = SetupReverseResolutionViewController.nibInstance()
        let presenter = SetupNewReverseResolutionDomainPresenter(view: vc,
                                                                 wallet: wallet,
                                                                 domains: domains,
                                                                 reverseResolutionDomain: reverseResolutionDomain,
                                                                 udWalletsService: appContext.udWalletsService,
                                                                 resultCallback: resultCallback)
        vc.presenter = presenter
        return vc
    }
    
    func buildSetupChangeReverseResolutionModule(wallet: WalletEntity,
                                                 domain: DomainDisplayInfo,
                                                 resultCallback: @escaping MainActorAsyncCallback) -> UIViewController {
        let vc = SetupReverseResolutionViewController.nibInstance()
        let presenter = SetupChangeReverseResolutionDomainPresenter(view: vc,
                                                                    wallet: wallet,
                                                                    domain: domain,
                                                                    udWalletsService: appContext.udWalletsService,
                                                                    resultCallback: resultCallback)
        vc.presenter = presenter
        return vc
    }
    
    func buildSetupReverseResolutionFlowModule(mode: SetupWalletsReverseResolutionNavigationManager.Mode,
                                               wallet: WalletEntity,
                                               resultCallback: @escaping SetupWalletsReverseResolutionNavigationManager.ReverseResolutionSetCallback) -> UIViewController {
        let vc = SetupWalletsReverseResolutionNavigationManager(mode: mode,
                                                                wallet: wallet)
        vc.reverseResolutionSetCallback = resultCallback
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
    
    func buildEnterEmailValueModule(email: String?,
                                    enteredEmailValueCallback: @escaping EnterEmailValueCallback) -> UIViewController {
        let vc = EnterValueViewController.nibInstance()
        let presenter = EnterEmailValuePresenter(view: vc,
                                                 email: email,
                                                 enteredEmailValueCallback: enteredEmailValueCallback)
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
    
    func buildInviteFriendsModule(domain: DomainItem) -> UIViewController {
        let vc = InviteFriendsViewController.nibInstance()
        let presenter = InviteFriendsViewPresenter(view: vc,
                                                   domain: domain)
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
        case walletsList
        case domainDetails
        case domainsCollection
    }
    
    enum UDRouterError: Error {
        case dismissed
    }
}
