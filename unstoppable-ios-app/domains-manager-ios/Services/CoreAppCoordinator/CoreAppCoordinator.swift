//
//  CoreAppCoordinator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import UIKit

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
    
    func showHome(mintingState: DomainsCollectionMintingState) {
        setDomainsCollectionScreenAsRoot(mintingState: mintingState)
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
            case .showDomainProfile(let domain, let walletWithInfo):
                guard let walletInfo = walletWithInfo.displayInfo else { throw CoordinatorError.incorrectArguments }
                
                await router.showDomainProfile(domain, wallet: walletWithInfo.wallet, walletInfo: walletInfo, dismissCallback: nil)
            case .primaryDomainMinted(let primaryDomain):
                await router.primaryDomainMinted(primaryDomain)
            case .showHomeScreenList:
                await router.showHomeScreenList()
            case .showPullUpLoading:
                guard let topVC = router.topViewController() else { throw CoordinatorError.noRootVC }
                
                pullUpViewService.showLoadingIndicator(in: topVC)
            }
        default:
            throw CoordinatorError.notSuitableRoot
        }
    }
}

// MARK: - WalletConnectUIHandler
extension CoreAppCoordinator: WalletConnectUIHandler {
    @discardableResult
    func getConfirmationToConnectServer(config: WCRequestUIConfiguration) async throws -> WalletConnectService.ConnectionUISettings {
        func awaitPullUpDisappear() async throws {
            try await Task.sleep(seconds: 0.2)
        }
        
        switch currentRoot {
        case .domainsCollection(let router):
            guard let hostView = router.topViewController() else { throw WalletConnectUIError.noControllerToPresent }
            do {
                Vibration.success.vibrate()
                let domainToProcessRequest = try await pullUpViewService
                    .showServerConnectConfirmationPullUp(for: config,
                                                         in: hostView)
                await hostView.dismissPullUpMenu()
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
    
    func didFailToConnect(with error: WalletConnectService.Error) {
        @MainActor func showErrorAlert(in hostView: UIViewController) {
            Vibration.error.vibrate()
            switch error.groupType {
            case .failedConnection, .connectionTimeout:
                pullUpViewService.showWCConnectionFailedPullUp(in: hostView)
            case .failedTx:
                pullUpViewService.showWCTransactionFailedPullUp(in: hostView)
            case .networkNotSupported:
                pullUpViewService.showNetworkNotSupportedPullUp(in: hostView)
            case .lowAllowance:
                pullUpViewService.showWCLowBalancePullUp(in: hostView)
            }
        }
        
        Task {
            await MainActor.run {
                switch currentRoot {
                case .domainsCollection(let router):
                    guard let hostView = router.topViewController() else { return }
                    
                    switch error.groupType {
                    case .connectionTimeout:
                        showErrorAlert(in: hostView)
                    case .failedConnection, .failedTx, .networkNotSupported, .lowAllowance:
                        if let pullUpView = hostView as? PullUpViewController,
                           pullUpView.pullUp != .wcLoading {
                            return
                        }
                        
                        showErrorAlert(in: hostView)
                    }
                default: return
                }
            }
        }
    }
    
    func didReceiveUnsupported(_ wcRequestMethodName: String) {
        Task {
            await MainActor.run {
                switch currentRoot {
                case .domainsCollection(let router):
                    guard let hostView = router.topViewController(),
                          !(hostView is PullUpViewController) else { return }
                    Vibration.error.vibrate()
                    pullUpViewService.showWCRequestNotSupportedPullUp(in: hostView)
                default: return
                }
            }
        }
    }
}

// MARK: - WalletConnectClientUIHandler
extension CoreAppCoordinator: WalletConnectClientUIHandler {
    func didDisconnect(walletDisplayInfo: WalletDisplayInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch self.currentRoot {
            case .domainsCollection, .onboarding:
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
                    
                    await self.pullUpViewService.showExternalWalletDisconnected(from: walletDisplayInfo, in: vc)
                    
                    await MainActor.run {
                        self.window?.makeKeyAndVisible()
                        self.topInfoWindow = nil
                    }
                }
            default: return
            }
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
    enum CoordinatorError: Error {
        case notSuitableRoot, noRootVC, incorrectArguments
    }
}

// MARK: - CurrentRoot
private extension CoreAppCoordinator {
    enum CurrentRoot {
        case none, onboarding, domainsCollection(router: DomainsCollectionRouter), appUpdate
    }
}
