//
//  LoginFlowNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import UIKit

@MainActor
protocol LoginFlowManager: AnyObject {
    func handle(action: LoginFlowNavigationController.Action) async throws
}

@MainActor
final class LoginFlowNavigationController: CNavigationController {
    
    typealias LoggedInCallback = ((Result)->())
    typealias LogInResult = Result
    
    private var mode: Mode = .default
    
    private let userDataService: UserDataServiceProtocol = appContext.userDataService
    private let domainsService: UDDomainsServiceProtocol = appContext.udDomainsService
    private let walletsService: UDWalletsServiceProtocol = appContext.udWalletsService
    private let transactionsService: DomainTransactionsServiceProtocol = appContext.domainTransactionsService
    private let notificationsService: NotificationsServiceProtocol = appContext.notificationsService
    
    var loggedInCallback: LoggedInCallback?
    
    convenience init(mode: Mode) {
        self.init()
        self.mode = mode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        setup()
    }
    
    override func popViewController(animated: Bool, completion: (()->())? = nil) -> UIViewController? {
        guard let topViewController = self.topViewController else {
            return super.popViewController(animated: animated)
        }
        
        if isLastViewController(topViewController) {
            navigationController?.popViewController(animated: true)
            return nil
        }
        return super.popViewController(animated: animated, completion: completion)
    }
}

// MARK: - MintDomainsFlowManager
extension LoginFlowNavigationController: LoginFlowManager {
    func handle(action: Action) async throws {
        switch action {
        case .loginWithEmailAndPassword:
            moveToStep(.loginWithEmailAndPassword)
        case .authorized(let provider):
            switch provider {
            case .email, .google, .twitter:
                try await fetchParkedDomains()
            case .apple:
                try await authorizedWithApple() 
            }
        case .importCompleted(let parkedDomains):
            dismiss(result: .loggedIn(parkedDomains: parkedDomains))
        }
    }
}

// MARK: - CNavigationControllerDelegate
extension LoginFlowNavigationController: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        setSwipeGestureEnabledForCurrentState()
    }
}

// MARK: - Open methods
extension LoginFlowNavigationController {
    func setMode(_ mode: Mode) {
        self.mode = mode
        setup()
    }
}

// MARK: - Private methods
private extension LoginFlowNavigationController {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
        
        self.pushViewController(vc, animated: true)
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        if viewController is ParkedDomainsFoundViewController ||
            viewController is NoParkedDomainsFoundViewController ||
            viewController is LoginViewController {
            return true
        } else if case .email = mode,
                  viewController is LoginWithEmailViewController {
            return true
        }
        return false
    }
    
    func dismiss(result: Result) {
        if let vc = presentedViewController {
            vc.dismiss(animated: true)
        }
        let loggedInCallback = self.loggedInCallback
        loggedInCallback?(result)
    }
    
    func setSwipeGestureEnabledForCurrentState() {
        guard let topViewController = viewControllers.last else { return }
        
        if topViewController is NoParkedDomainsFoundViewController ||
            topViewController is LoadingParkedDomainsViewPresenterProtocol ||
            topViewController is ParkedDomainsFoundViewController {
            transitionHandler?.isInteractionEnabled = false
            cNavigationController?.transitionHandler?.isInteractionEnabled = false
            navigationBar.alwaysShowBackButton = false
            navigationBar.setBackButton(hidden: true)
        } else {
            transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
            cNavigationController?.transitionHandler?.isInteractionEnabled = isLastViewController(topViewController)
        }
    }
    
    func fetchParkedDomains() async throws {
        do {
            await MainActor.run {
                moveToStep(.fetchingDomains)
            }
            await Task.sleep(seconds: CNavigationController.animationDuration)
            let parkedDomains = try await appContext.firebaseParkedDomainsService.getParkedDomains()
            let displayInfo = parkedDomains.map({ FirebaseDomainDisplayInfo(firebaseDomain: $0) })
            
            await MainActor.run {
                if parkedDomains.isEmpty {
                    moveToStep(.noParkedDomains)
                } else {
                    moveToStep(.parkedDomainsFound(parkedDomains: displayInfo))
                }
            }
        } catch {
            await MainActor.run {
                moveToStep(.noParkedDomains)
            }
        }
    }
    
    func authorizedWithApple() async throws {
        moveToStep(.fetchingDomains)
        await Task.sleep(seconds: 1.5)
        moveToStep(.noParkedDomains)
    }
    
    func createDomainsOrderInfoMap(for domains: [String]) -> SortDomainsOrderInfoMap {
        var map = SortDomainsOrderInfoMap()
        for (i, domain) in domains.enumerated() {
            map[domain] = i
        }
        return map
    }
}

// MARK: - Setup methods
private extension LoginFlowNavigationController {
    func setup() {
        isModalInPresentation = true
        setupBackButtonAlwaysVisible()
        
        switch mode {
        case .email:
            if let initialViewController = createStep(.loginWithEmailAndPassword) {
                setViewControllers([initialViewController], animated: false)
            }
        case .authorized(let provider):
            setViewControllers([UIViewController()], animated: false)
            Task {
                try? await handle(action: .authorized(provider))
            }
        case .default, .onboarding:
            if let initialViewController = createStep(.selectLoginOption) {
                setViewControllers([initialViewController], animated: false)
            }
        }
        setSwipeGestureEnabledForCurrentState()
    }
    
    func setupBackButtonAlwaysVisible() {
        navigationBar.alwaysShowBackButton = true
        navigationBar.setBackButton(hidden: false)
    }
    
    func createStep(_ step: Step) -> UIViewController? {
        switch step {
        case .selectLoginOption:
            let vc = LoginViewController.nibInstance()
            let presenter = LoginInAppViewPresenter(view: vc,
                                                    loginFlowManager: self)
            vc.presenter = presenter
            return vc
        case .loginWithEmailAndPassword:
            let vc = LoginWithEmailViewController.nibInstance()
            let presenter = LoginWithEmailInAppViewPresenter(view: vc, loginFlowManager: self)
            vc.presenter = presenter
            return vc
        case .noParkedDomains:
            let vc = NoParkedDomainsFoundViewController.nibInstance()
            let presenter = NoParkedDomainsFoundInAppViewPresenter(view: vc,
                                                                   loginFlowManager: self)
            vc.presenter = presenter
            
            return vc
        case .parkedDomainsFound(let domains):
            let vc = ParkedDomainsFoundViewController.nibInstance()
            let presenter = ParkedDomainsFoundInAppViewPresenter(view: vc,
                                                                 domains: domains,
                                                                 loginFlowManager: self)
            vc.presenter = presenter
            return vc
        case .fetchingDomains:
            let vc = LoadingParkedDomainsViewController.nibInstance()
            let presenter = LoadingParkedDomainsInAppViewPresenter(view: vc,
                                                                   loginFlowManager: self)
            vc.presenter = presenter
            return vc
        }
    }
}

// MARK: - Private methods
private extension LoginFlowNavigationController {
    struct MintingData {
        var email: String? = nil
        var code: String? = nil
        var wallet: UDWallet? = nil
    }
}

extension LoginFlowNavigationController {
    enum Mode {
        case `default`
        case email
        case authorized(LoginProvider)
        case onboarding
    }
    
    enum Step: Codable {
        case selectLoginOption
        case loginWithEmailAndPassword
        case noParkedDomains
        case parkedDomainsFound(parkedDomains: [FirebaseDomainDisplayInfo])
        case fetchingDomains
    }
    
    enum Action {
        case loginWithEmailAndPassword
        case authorized(LoginProvider)
        case importCompleted(parkedDomains: [FirebaseDomainDisplayInfo])
    }
    
    enum Result {
        case cancel
        case failedToLoadParkedDomains
        case loggedIn(parkedDomains: [FirebaseDomainDisplayInfo])
    }
}


import SwiftUI
@MainActor
struct LoginFlowNavigationControllerWrapper: UIViewControllerRepresentable {
    
    let mode: LoginFlowNavigationController.Mode
    var callback: LoginFlowNavigationController.LoggedInCallback? = nil
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = LoginFlowNavigationController(mode: mode)
        vc.loggedInCallback = callback
        let nav = EmptyRootCNavigationController(rootViewController: vc)
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
}
