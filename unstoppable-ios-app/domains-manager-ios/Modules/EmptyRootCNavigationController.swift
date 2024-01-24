//
//  EmptyRootCNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.08.2022.
//

import UIKit

final class EmptyRootCNavigationController: CNavigationController {
    
    var dismissCallback: EmptyCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.alwaysShowBackButton = true
        navigationBar.setBackButton(hidden: false)
        transitionHandler.isInteractionEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presentationController?.delegate = self
        navigationBar.navBarContentView.backButton.accessibilityIdentifier = "Empty Navigation Back Button"
    }
    
    override func popViewController(animated: Bool, completion: (()->())? = nil) -> UIViewController?  {
        UDVibration.buttonTap.vibrate()
        guard canMoveBack else { return nil }

        if let cNavigationController = self.cNavigationController {
            cNavigationController.popViewController(animated: true)
        } else if topViewController is EmptyRootCNavigationController || topViewController != rootViewController {
            transitionHandler.isInteractionEnabled = topViewController != rootViewController
            return super.popViewController(animated: animated, completion: completion)
        } else if let navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismissCallback?()
            presentingViewController?.dismiss(animated: true)
        }
        return nil
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        transitionHandler.isInteractionEnabled = true
        super.pushViewController(viewController, animated: animated)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension EmptyRootCNavigationController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissCallback?()
    }
}

// MARK: - CNavigationControllerChildNavigationHandler
extension EmptyRootCNavigationController: CNavigationControllerChildNavigationHandler {
    func cNavigationChildDidDismissed() {
        dismissCallback?()
    }
}
