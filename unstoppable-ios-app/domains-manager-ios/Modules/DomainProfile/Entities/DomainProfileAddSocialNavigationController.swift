//
//  DomainProfileAddSocialManager.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import UIKit

@MainActor
protocol DomainProfileAddSocialManager: AnyObject {
    func handle(action: DomainProfileAddSocialNavigationController.Action) async throws
}

final class DomainProfileAddSocialNavigationController: CNavigationController {
    
    typealias SocialVerifiedCallback = ((Result)->())

    private var mode: Mode = .domainProfile
    private var socialType: SocialsType = .twitter
    var socialVerifiedCallback: SocialVerifiedCallback?
    
    convenience init(mode: Mode, socialType: SocialsType) {
        self.init()
        self.mode = mode
        self.socialType = socialType
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
        
        if topViewController is EnterValueViewController {
            return cNavigationController?.popViewController(animated: true)
        }
        return super.popViewController(animated: animated, completion: completion)
    }
}

// MARK: - DomainProfileAddSocialManager
extension DomainProfileAddSocialNavigationController: DomainProfileAddSocialManager {
    func handle(action: Action) async throws {
        switch action {
        case .didEnterValue(let value):
            moveToStep(.confirmVerify(value: value))
        case .verifyPressed(let value):
            moveToStep(.verify(value: value))
        case .didVerify(let value):
            didFinishVerification(value: value)
        }
    }
}

// MARK: - CNavigationControllerDelegate
extension DomainProfileAddSocialNavigationController: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        setSwipeGestureEnabledForCurrentState()
    }
}

// MARK: - Private methods
private extension DomainProfileAddSocialNavigationController {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
        
        self.pushViewController(vc, animated: true)
    }
    
    func didFinishVerification(value: String) {
        dismiss(result: .verified(value: value))
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        return viewController is EnterValueViewController
    }
    
    func dismiss(result: Result) {
        if let vc = presentedViewController {
            vc.dismiss(animated: true)
        }
        cNavigationController?.transitionHandler?.isInteractionEnabled = true
        let socialVerifiedCallback = self.socialVerifiedCallback
        self.cNavigationController?.popViewController(animated: true) {
            socialVerifiedCallback?(result)
        }
    }
    
    func setSwipeGestureEnabledForCurrentState() {
        guard let topViewController = viewControllers.last else { return }
        
        transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
        cNavigationController?.transitionHandler?.isInteractionEnabled = isLastViewController(topViewController)
    }
}

// MARK: - Setup methods
private extension DomainProfileAddSocialNavigationController {
    func setup() {
        isModalInPresentation = true
        setupBackButtonAlwaysVisible()
        
        switch mode {
        case .domainProfile:
            if let initialViewController = createStep(.enterValue) {
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
        case .enterValue:
            let vc = EnterValueViewController.nibInstance()
            let presenter = EnterDomainProfileSocialValuePresenter(view: vc,
                                                                   socialType: socialType,
                                                                   domainProfileAddSocialManager: self)
            vc.presenter = presenter
            return vc
        case .confirmVerify(let value):
            let vc = SocialsVerificationViewController.nibInstance()
            let presenter = DomainProfileSocialsVerificationPresenter(view: vc,
                                                                      socialType: socialType,
                                                                      value: value,
                                                                      domainProfileAddSocialManager: self)
            vc.presenter = presenter
            return vc
        case .verify(let value):
            let vc = EnterValueViewController.nibInstance()
            let presenter = EnterValueViewPresenter(view: vc, value: value)
            vc.presenter = presenter
            return vc
        }
    }
}

extension DomainProfileAddSocialNavigationController {
    enum Mode {
        case domainProfile
    }
    
    enum Step {
        case enterValue
        case confirmVerify(value: String)
        case verify(value: String)
    }
    
    enum Action {
        case didEnterValue(_ value: String)
        case verifyPressed(value: String)
        case didVerify(value: String)
    }
    
    enum Result {
        case cancel
        case verified(value: String)
    }
    
}
