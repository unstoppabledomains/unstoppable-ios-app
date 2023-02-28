//
//  SceneDelegate.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 02.10.2020.
//

import UIKit

@MainActor
protocol SceneDelegateProtocol {
    var interfaceOrientation: UIInterfaceOrientation { get }
    var window: MainWindow? { get }
    var sceneActivationState: UIScene.ActivationState { get }
    func setAppearanceStyle(_ appearanceStyle: UIUserInterfaceStyle)
    func authorizeUserOnAppOpening() async
    func restartOnboarding()
    
    func addListener(_ listener: SceneActivationListener)
    func removeListener(_ listener: SceneActivationListener)
}

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        
    static let shared: SceneDelegateProtocol? = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegateProtocol

    private var securityWindow: SecurityWindow?
    private var didResolveInitialViewController = false
    private var authHandler = AuthorizationHandler()
    var window: MainWindow?
    var sceneActivationState: UIScene.ActivationState { window?.windowScene?.activationState ?? .unattached }
    private var listeners: [SceneActivationListenerHolder] = []

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = MainWindow(windowScene: windowScene)
        self.window = window
        securityWindow = SecurityWindow(windowScene: windowScene)
        setupSecurityWindow()
        
        #if DEBUG
        if TestsEnvironment.isTestModeOn {
            Debugger.printInfo("Application running in test mode")
            UIView.setAnimationsEnabled(false)
            window.layer.speed = 100
        }
        #endif
        
        appContext.coreAppCoordinator.startWith(window: window)
        appContext.appLaunchService.startWith(sceneDelegate: self,
                                              walletConnectService: appContext.walletConnectService,
                                              walletConnectServiceV2: appContext.walletConnectServiceV2,
                                              walletConnectClientService: appContext.walletConnectClientService,
                                              completion: { Task { await MainActor.run { self.didResolveInitialViewController = true } } })
        
        setAppearanceStyle(UserDefaults.appearanceStyle)
        let networkReachabilityService = appContext.networkReachabilityService
        networkReachabilityService?.startListening()
        networkReachabilityService?.addListener(self)
        networkStatusChanged(networkReachabilityService?.status ?? .reachable(.cellular))
        
        // simulation of entry to the app via Universal Link with email
        guard ProcessInfo.processInfo.environment["SHOULD_SIMULATE_UNIVERSAL_LINK"] != "TRUE" else {
            let deepLink = "https://staging.unstoppabledomains.com/mobile?operation=MobileMintDomains&email=foto240@gmail.com&code=123456"
            handleUniversalLink(URL(string: deepLink)!, receivedState: .background)
            return
        }
        
        appContext.notificationsService.registerRemoteNotifications()

        if let userActivity = connectionOptions.userActivities.first,
              userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL {
            handleUniversalLink(incomingURL, receivedState: .background)
        } else if let incomingURL = connectionOptions.urlContexts.first?.url {
            handleUniversalLink(incomingURL, receivedState: .background)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let incomingURL = URLContexts.first?.url {
            handleUniversalLink(incomingURL, receivedState: .foreground)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return
        }
        handleUniversalLink(incomingURL, receivedState: .foreground)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        notifyListenersActivationStateChanged(scene.activationState)
        appContext.analyticsService.log(event: .appGoesToBackground, withParameters: nil)
        blurIfNeeded()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        notifyListenersActivationStateChanged(scene.activationState)

        appContext.analyticsService.log(event: .appGoesToForeground, withParameters: nil)
        guard didResolveInitialViewController else { return }
        
        Task {
            await authorizeUserOnAppOpening()
            appContext.externalEventsService.checkPendingEvents()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        notifyListenersActivationStateChanged(scene.activationState)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        notifyListenersActivationStateChanged(scene.activationState)
        Task.detached { [unowned self] in
            let isAuthorizingUser = await self.authHandler.isAuthorizing
            if !isAuthorizingUser {
                await self.unBlur(animated: false)
            }
        }
    }
    
    private func notifyListenersActivationStateChanged(_ newState: SceneActivationState) {
        listeners.forEach { holder in
            holder.listener?.didChangeSceneActivationState(to: newState)
        }
    }
}

// MARK: - SceneDelegateProtocol
extension SceneDelegate: SceneDelegateProtocol {
    var interfaceOrientation: UIInterfaceOrientation { window?.windowScene?.interfaceOrientation ?? .unknown }

    func setAppearanceStyle(_ appearanceStyle: UIUserInterfaceStyle) {
        window?.overrideUserInterfaceStyle = appearanceStyle
        securityWindow?.overrideUserInterfaceStyle = appearanceStyle
        UserDefaults.appearanceStyle = appearanceStyle
    }
    
    func authorizeUserOnAppOpening() async {
        guard let rootVC = securityWindow?.rootViewController else { return }
        guard User.instance.getSettings().shouldRequireSAOnAppOpening else {
            await unBlurAfterAuthorization()
            return
        }
        
        blurIfNeeded() // To blur content when user just launched the app.
        do {
            logSAAnalyticsIfEnabled(event: .secureAuthStarted)
            try await authHandler.authorize(with: rootVC)
            logSAAnalyticsIfEnabled(event: .secureAuthPassed)
            await unBlurAfterAuthorization()
            appContext.coreAppCoordinator.setKeyWindow()
        } catch {
            logSAAnalyticsIfEnabled(event: .secureAuthFailed)
            await authorizeUserOnAppOpening()
        }
    }
    
    func restartOnboarding() {
        appContext.analyticsService.log(event: .willRestartOnboarding, withParameters: nil)
        var settings = User.instance.getSettings()
        settings.onboardingDone = false
        User.instance.update(settings: settings)
        SecureHashStorage.clearPassword()
        appContext.coreAppCoordinator.showOnboarding(.sameUserWithoutWallets(subFlow: nil))
    }
    
    func addListener(_ listener: SceneActivationListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: SceneActivationListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - NetworkReachabilityServiceListener
extension SceneDelegate: NetworkReachabilityServiceListener {
    func networkStatusChanged(_ status: NetworkReachabilityService.Status) {
        DispatchQueue.main.async {
            if appContext.networkReachabilityService?.isReachable == false {
                appContext.toastMessageService.showToast(.noInternetConnection, isSticky: true)
            } else {
                appContext.toastMessageService.removeStickyToast(.noInternetConnection)
            }
        }
    }
}

// MARK: - Universal links
private extension SceneDelegate {
    func handleUniversalLink(_ incomingURL: URL, receivedState: ExternalEventReceivedState) {
        Task {
            let isAuthorizing = await authHandler.isAuthorizing
            
            if isAuthorizing {
                await authorizeUserOnAppOpening()
                appContext.deepLinksService.handleUniversalLink(incomingURL, receivedState: receivedState)
            } else {
                appContext.deepLinksService.handleUniversalLink(incomingURL, receivedState: receivedState)
            }
        }
    }
}

// MARK: - Cover blur view
private extension SceneDelegate {
    var isBlurViewCoveringScreen: Bool { securityWindow?.isBlurViewCoveringScreen ?? false }
    
    func blurIfNeeded(completion: EmptyCallback? = nil) {
        guard !isBlurViewCoveringScreen else {
            completion?()
            return
        }
        
        setBlurViewCoveringScreen(true, animated: false, completion: completion)
    }
    
    func unBlurAfterAuthorization(completion: EmptyCallback? = nil) {
        unBlur(animated: true, completion: completion)
    }
    
    func unBlurAfterAuthorization() async {
        await withSafeCheckedMainActorContinuation { completion in
            unBlurAfterAuthorization {
                completion(Void())
            }
        }
    }
    
    func unBlur(animated: Bool, completion: EmptyCallback? = nil) {
        guard isBlurViewCoveringScreen else {
            completion?()
            return
        }
        
        setBlurViewCoveringScreen(false, animated: animated, completion: completion)
    }
    
    func setBlurViewCoveringScreen(_ isCovering: Bool, animated: Bool, completion: EmptyCallback? = nil) {
        if isCovering {
            securityWindow?.blurTopMostViewController()
            switch SecureAuthenticationType.current {
            case .passcode:
                window?.dismissActivityController()
            case .biometric:
                Void()
            }
            setKeyWindow(self.securityWindow!, animated: animated, completion: completion)
        } else {
            securityWindow?.unblurTopMostViewController()
            setKeyWindow(self.window!, animated: animated, completion: completion)
        }
    }
     
    func setKeyWindow(_ window: UIWindow, animated: Bool, completion: EmptyCallback? = nil) {
        if animated {
            let animationDuration: TimeInterval = User.instance.getSettings().touchIdActivated ? 0.1 : 0.25
            let delay: TimeInterval = animated ? animationDuration : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                window.makeKeyAndVisible()
                completion?()
            }
        } else {
            window.makeKeyAndVisible()
            completion?()
        }
    }
}

// MARK: - Initial View Controller
private extension SceneDelegate {
    func setupSecurityWindow() {
        let vc = UIViewController()
        securityWindow?.rootViewController = vc
    }
}

// MARK: - AuthorizationHandler
private extension SceneDelegate {
    actor AuthorizationHandler {
        var isAuthorizing: Bool { currentAuthTask != nil }
        private var currentAuthTask: Task<Void, Error>?
        
        func authorize(with uiHandler: AuthenticationUIHandler) async throws {
            if let currentTask = currentAuthTask {
                let _ = try await currentTask.value
                return
            }
         
            guard appContext.authentificationService.isSecureAuthSet else { return }
            
            do {
                let task: Task<Void, Error> = Task.detached(priority: .high) {
                    try await appContext.authentificationService.verifyWith(uiHandler: uiHandler,
                                                                         purpose: .unlock)
                }
                currentAuthTask = task

                let _ = try await task.value
                currentAuthTask = nil
            } catch {
                currentAuthTask = nil
                throw error
            }
        }
    }
}

// MARK: - Private methods
private extension SceneDelegate {
    func logSAAnalyticsIfEnabled(event: Analytics.Event) {
        guard appContext.authentificationService.isSecureAuthSet else { return }
        
        appContext.analyticsService.log(event: event, withParameters: [.secureAuthType : SecureAuthenticationType.current.analyticName])
    }
}

extension SceneDelegate {
    enum SecureAuthenticationType {
        case biometric, passcode
        
        static var current: SecureAuthenticationType {
            if User.instance.getSettings().touchIdActivated {
                return .biometric
            }
            return .passcode
        }
        
        var analyticName: String {
            switch self {
            case .biometric:
                return appContext.authentificationService.biometricsName ?? "biometric"
            case .passcode:
                return "passcode"
            }
        }
    }
}

typealias SceneActivationState = UIScene.ActivationState

protocol SceneActivationListener: AnyObject {
    func didChangeSceneActivationState(to state: SceneActivationState)
}

final class SceneActivationListenerHolder: Equatable {
    
    weak var listener: SceneActivationListener?
    
    init(listener: SceneActivationListener) {
        self.listener = listener
    }
    
    static func == (lhs: SceneActivationListenerHolder, rhs: SceneActivationListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
