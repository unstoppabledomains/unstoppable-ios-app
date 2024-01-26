//
//  CoreAppCoordinator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import UIKit
import SwiftUI

@MainActor
final class CoreAppCoordinator {
    
    private let pullUpViewService: PullUpViewServiceProtocol
    private var window: UIWindow?
    private var topInfoWindow: UIWindow?
    private var currentRoot: CurrentRoot = .none
    private var pendingDeepLinkEvent: DeepLinkEvent?
    
    nonisolated
    init(pullUpViewService: PullUpViewServiceProtocol) {
        self.pullUpViewService = pullUpViewService
    }
    
}

// MARK: - CoreAppCoordinatorProtocol
extension CoreAppCoordinator: CoreAppCoordinatorProtocol {
    func startWith(window: UIWindow) {
        guard self.window == nil else {
            Debugger.printFailure("Trying to start core coordinator second time", critical: false)
            return
        }
        
        self.window = window
        window.makeKeyAndVisible()
        setLaunchScreenAsRoot()
    }
    
    func showOnboarding(_ flow: OnboardingNavigationController.OnboardingFlow) {
        setOnboardingAsRoot(flow)
    }
    
    func showHome(mintingState: DomainsCollectionMintingState, wallet: WalletEntity) {
//        setDomainsCollectionScreenAsRoot(mintingState: mintingState)
        setHomeScreenAsRoot(wallet: wallet) // TODO: - Refactoring
        if let event = pendingDeepLinkEvent {
            handleDeepLinkEvent(event)
        }
    }
    
    func showAppUpdateRequired() {
        let appUpdateRequiredVC = AppUpdatedRequired.nibInstance()
        setRootViewController(appUpdateRequiredVC)
        currentRoot = .appUpdate
    }
    
    func setKeyWindow() {
        window?.makeKeyAndVisible()
        topInfoWindow?.makeKeyAndVisible()
    }
    
    @discardableResult
    func goBackToPreviousApp() -> Bool {
        goBackToPreviousAppIfCan()
    }
    
    func didRegisterShakeDevice() {
        switch currentRoot {
        case .domainsCollection(let router):
            router.didRegisterShakeDevice()
        case .home(let router):
            router.didRegisterShakeDevice()
        default:
            return 
        }
    }
    
    func isActiveState(_ state: AppCoordinationState) -> Bool {
        switch currentRoot {
        case .domainsCollection(let router):
            switch state {
            case .chatOpened(let chatId):
                return router.isChatOpenedWith(chatId: chatId)
            case .channelOpened(let channelId):
                return router.isChannelOpenedWith(channelId: channelId)
            }
        default:
            return false
        }
    }
    
    var topVC: UIViewController? { window?.rootViewController?.topVisibleViewController() }
}

// MARK: - DeepLinkServiceListener
extension CoreAppCoordinator: DeepLinkServiceListener {
    func didReceiveDeepLinkEvent(_ event: DeepLinkEvent, receivedState: ExternalEventReceivedState) {
        if case .none = currentRoot {
            pendingDeepLinkEvent = event
            return
        }
        
        handleDeepLinkEvent(event)
    }
}

// MARK: - ExternalEventsUIHandler
extension CoreAppCoordinator: ExternalEventsUIHandler {
    func handle(uiFlow: ExternalEventUIFlow) async throws {
        switch currentRoot {
        case .domainsCollection(let router):
            switch uiFlow {
            case .showDomainProfile(let domain, let wallet):
                await router.showDomainProfile(domain,
                                               wallet: wallet.udWallet,
                                               walletInfo: wallet.displayInfo,
                                               preRequestedAction: nil,
                                               dismissCallback: nil)
            case .primaryDomainMinted(let primaryDomain):
                await router.primaryDomainMinted(primaryDomain)
            case .showHomeScreenList:
                await router.showHomeScreenList()
            case .showPullUpLoading:
                guard let topVC = router.topViewController() else { throw CoordinatorError.noRootVC }
                
                pullUpViewService.showLoadingIndicator(in: topVC)
            case .showChat(let chatId, let profile):
                await router.showChat(chatId, profile: profile)
            case .showNewChat(let description, let profile):
                await router.showChatWith(options: .newChat(description: description), profile: profile)
            case .showChannel(let channelId, let profile):
                await router.showChannel(channelId, profile: profile)
            case .showChatsList(let profile):
                await router.jumpToChatsList(profile: profile)
            }
        case .home(let router):
            switch uiFlow {
            case .showDomainProfile(let domain, let wallet):
                await router.showDomainProfile(domain,
                                               wallet: wallet,
                                               preRequestedAction: nil,
                                               dismissCallback: nil)
            case .primaryDomainMinted(let primaryDomain):
                await router.primaryDomainMinted(primaryDomain)
            case .showHomeScreenList:
                await router.showHomeScreenList()
            case .showPullUpLoading:
                guard let topVC else { throw CoordinatorError.noRootVC }
                
                pullUpViewService.showLoadingIndicator(in: topVC)
            case .showChat(let chatId, let profile):
                await router.showChat(chatId, profile: profile)
            case .showNewChat(let description, let profile):
                await router.showChatWith(options: .newChat(description: description), profile: profile)
            case .showChannel(let channelId, let profile):
                await router.showChannel(channelId, profile: profile)
            case .showChatsList(let profile):
                await router.jumpToChatsList(profile: profile)
            }
        default:
            throw CoordinatorError.notSuitableRoot
        }
    }
}

// MARK: - WalletConnectUIHandler
extension CoreAppCoordinator: WalletConnectUIConfirmationHandler, WalletConnectUIErrorHandler {
    @discardableResult
    func getConfirmationToConnectServer(config: WCRequestUIConfiguration) async throws -> WalletConnectServiceV2.ConnectionUISettings {
        switch currentRoot {
        case .domainsCollection, .home:
            func awaitPullUpDisappear() async throws {
                try await Task.sleep(seconds: 0.2)
            }
            guard let topVC else { throw WalletConnectUIError.noControllerToPresent }
            do {
                Vibration.success.vibrate()
                let domainToProcessRequest = try await pullUpViewService
                    .showServerConnectConfirmationPullUp(for: config,
                                                         in: topVC)
                await topVC.dismissPullUpMenu()
                AppReviewService.shared.appReviewEventDidOccurs(event: .didHandleWCRequest)
                return domainToProcessRequest
            } catch {
                try? await awaitPullUpDisappear()
                AppReviewService.shared.appReviewEventDidOccurs(event: .didHandleWCRequest)
                throw WalletConnectUIError.cancelled
            }
        default: throw WalletConnectUIError.cancelled
        }
    }
    
    @MainActor
    func didFailToConnect(with error: WalletConnectRequestError) async {
        switch currentRoot {
        case .domainsCollection, .home:
            @MainActor
            func showErrorAlert(in hostView: UIViewController) async {
                Vibration.error.vibrate()
                switch error.groupType {
                case .failedConnection, .connectionTimeout:
                    await pullUpViewService.showWCConnectionFailedPullUp(in: hostView)
                case .failedTx:
                    await pullUpViewService.showWCTransactionFailedPullUp(in: hostView)
                case .networkNotSupported:
                    await pullUpViewService.showNetworkNotSupportedPullUp(in: hostView)
                case .lowAllowance:
                    await pullUpViewService.showWCLowBalancePullUp(in: hostView)
                case .methodUnsupported:
                    await pullUpViewService.showWCRequestNotSupportedPullUp(in: hostView)
                }
            }
            guard let topVC else { return }
            
            switch error.groupType {
            case .connectionTimeout:
                await showErrorAlert(in: topVC)
            case .failedConnection, .failedTx, .networkNotSupported, .lowAllowance, .methodUnsupported:
                if let pullUpView = topVC as? PullUpViewController,
                   pullUpView.pullUp != .wcLoading {
                    return
                }
                
                await showErrorAlert(in: topVC)
            }
        default: return
        }
    }
    
    @MainActor
    func dismissLoadingPageIfPresented() async {
        switch currentRoot {
        case .domainsCollection(let router):
            guard let hostView = router.topViewController() else { return }
            
            if let pullUpView = hostView as? PullUpViewController,
               pullUpView.pullUp == .wcLoading {
                await hostView.dismissPullUpMenu()
            }
        case .home(let router):
            if router.pullUp?.analyticName == .wcLoading {
                await router.dismissPullUpMenu()
            }
        default: return
        }
    }
}

// MARK: - WalletConnectClientUIHandler
extension CoreAppCoordinator: WalletConnectClientUIHandler {
    func didDisconnect(walletDisplayInfo: WalletDisplayInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch self.currentRoot {
            case .domainsCollection, .onboarding, .home:
                guard let windowScene = self.window?.windowScene else { return }
                
                Task {
                    let vc = UIViewController()
                    await MainActor.run {
                        let topInfoWindow = UIWindow(windowScene: windowScene)
                        topInfoWindow.overrideUserInterfaceStyle = UserDefaults.appearanceStyle
                        self.topInfoWindow = topInfoWindow
                        topInfoWindow.backgroundColor = .clear
                        vc.view.backgroundColor = .clear
                        vc.modalPresentationStyle = .overFullScreen
                        topInfoWindow.rootViewController = vc
                        topInfoWindow.makeKeyAndVisible()
                    }
                    
                    _ = await self.pullUpViewService.showExternalWalletDisconnected(from: walletDisplayInfo, in: vc)
                    
                    await MainActor.run {
                        self.window?.makeKeyAndVisible()
                        self.topInfoWindow = nil
                    }
                }
            default: return
            }
        }
    }
    
    func askToReconnectExternalWallet(_ walletDisplayInfo: WalletDisplayInfo) async -> Bool {
        switch self.currentRoot {
        case .domainsCollection, .home:
            guard let topVC else { return false }

            let response = await self.pullUpViewService.showExternalWalletDisconnected(from: walletDisplayInfo, in: topVC)
            await topVC.dismissPullUpMenu()
            return response 
        default: return false
        }
    }
    
    func showExternalWalletDidNotRespondPullUp(for connectingWallet: WCWalletsProvider.WalletRecord) async {
        switch self.currentRoot {
        case .domainsCollection, .home:
            guard let topVC else { return }

            await appContext.pullUpViewService.showExternalWalletConnectionHintPullUp(for: connectingWallet,
                                                                                in: topVC)
        default: return
        }
    }
    
}

// MARK: - Passing events
private extension CoreAppCoordinator {
    func handleDeepLinkEvent(_ event: DeepLinkEvent) {
        switch currentRoot {
        case .domainsCollection(let router):
            switch event {
            case .mintDomainsVerificationCode(let email, let code):
                router.runMintDomainsFlow(with: .deepLink(email: email, code: code))
            case .showUserDomainProfile(let domain, let wallet, let action):
                Task { await router.showDomainProfile(domain, wallet: wallet.udWallet, walletInfo: wallet.displayInfo, preRequestedAction: action, dismissCallback: nil) }
            case .showPublicDomainProfile(let publicDomainDisplayInfo, let viewingDomain, let action):
                Task { await router.showPublicDomainProfileFromDeepLink(of: publicDomainDisplayInfo, viewingDomain: viewingDomain, preRequestedAction: action) }
            }
        case .home(let router):
            switch event {
            case .mintDomainsVerificationCode(let email, let code):
                router.runMintDomainsFlow(with: .deepLink(email: email, code: code))
            case .showUserDomainProfile(let domain, let wallet, let action):
                Task { await router.showDomainProfile(domain, wallet: wallet, preRequestedAction: action, dismissCallback: nil) }
            case .showPublicDomainProfile(let publicDomainDisplayInfo, let viewingDomain, let action):
                Task { await router.showPublicDomainProfileFromDeepLink(of: publicDomainDisplayInfo, viewingDomain: viewingDomain, preRequestedAction: action) }
            }
        default: return
        }
    }
}

// MARK: - Private methods
private extension CoreAppCoordinator {
    func setLaunchScreenAsRoot() {
        let launchVC = LaunchViewController.nibInstance()
        setRootViewController(launchVC)
    }

    func setDomainsCollectionScreenAsRoot(mintingState: DomainsCollectionMintingState) {
        let router = DomainsCollectionRouter()
        let vc = router.configureViewController(mintingState: mintingState)
        setRootViewController(vc)
        currentRoot = .domainsCollection(router: router)
    }
    
    func setHomeScreenAsRoot(wallet: WalletEntity) {
        let router = HomeTabRouter()
        let view = HomeTabView(selectedWallet: wallet, tabRouter: router)
        let vc = UIHostingController(rootView: view)
        setRootViewController(vc)
        currentRoot = .home(router: router)
    }
    
    func setOnboardingAsRoot(_ flow: OnboardingNavigationController.OnboardingFlow) {
        let onboardingVC = OnboardingNavigationController.instantiate(flow: flow)
        setRootViewController(onboardingVC)
        currentRoot = .onboarding
    }
    
    func setRootViewController(_ rootViewController: UIViewController) {
        guard let window = self.window else { return }
        
        Debugger.printInfo(topic: .Navigation, "Set Root based off: \(self)")
        window.rootViewController = rootViewController
        
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        UIView.transition(with: window,
                          duration: 0.3,
                          options: options,
                          animations: { })
    }
    
    func goBackToPreviousAppIfCan() -> Bool {
        let app = UIApplication.shared
        let selector = Selector(("sendResponseForDestination:"))
        if let sysNavIvar = class_getInstanceVariable(UIApplication.self, "_systemNavigationAction"),
           let actionObject = object_getIvar(app, sysNavIvar) as? NSObject,
           actionObject.responds(to: selector),
           let destinations = actionObject.value(forKey: "destinations") as? [Int],
           destinations.count > 1 {
            let destination = destinations[destinations.count - 2] // Get previous screen
            actionObject.perform(selector, with: destination)
            return true
        } else {
            return false
        }
    }
}

// MARK: - CoordinatorError
extension CoreAppCoordinator {
    enum CoordinatorError: String, LocalizedError {
        case notSuitableRoot, noRootVC, incorrectArguments
        
        public var errorDescription: String? { rawValue }
    }
}

// MARK: - CurrentRoot
private extension CoreAppCoordinator {
    enum CurrentRoot {
        case none, onboarding, domainsCollection(router: DomainsCollectionRouter), appUpdate
        case home(router: HomeTabRouter)
    }
}
