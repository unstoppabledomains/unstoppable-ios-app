//
//  UDNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2022.
//

import UIKit

protocol UDNavigationBackButtonHandler {
    func shouldPopOnBackButton() -> Bool
}

class UDNavigationController: UINavigationController {
    
    var canMoveBack: Bool { (topViewController as? UDNavigationBackButtonHandler)?.shouldPopOnBackButton() ?? true }
    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    private var statusBarStyle: UIStatusBarStyle = .default
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        interactivePopGestureRecognizer?.isEnabled = false
        delegate = self
        interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleSwipeGesture))
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        guard canMoveBack else { return nil }
        
        return super.popViewController(animated: animated)
    }

    func updateStatusBar(for viewController: UIViewController) {
        statusBarStyle = viewController.preferredStatusBarStyle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension UDNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        updateStatusBar(for: viewController)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    }
}

// MARK: - Open methods
extension UDNavigationController {
    @objc func handleSwipeGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.transitionCoordinator?.notifyWhenInteractionChanges({ [weak self] context in
                if context.completionVelocity < 0, // will restore current view controller
                   let viewController = context.viewController(forKey: .from) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + context.transitionDuration) { [weak self] in
                        self?.updateStatusBar(for: viewController)
                    }
                }
            })
        default:
            return
        }
    }
}
