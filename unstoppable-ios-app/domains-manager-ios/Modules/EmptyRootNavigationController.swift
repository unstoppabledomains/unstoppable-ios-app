//
//  EmptyRootNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.05.2022.
//

import UIKit

final class EmptyRootNavigationController: UDNavigationController {
        
    var dismissCallback: EmptyCallback?
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        setViewControllerWithEmptyRoot(rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presentationController?.delegate = self
        interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        if let baseVC = topViewController as? BaseViewController {
            baseVC.logButtonPressedAnalyticEvents(button: .close)
        }
        
        UDVibration.buttonTap.vibrate()
        guard canMoveBack else { return nil }
        
        dismissCallback?()
        dismiss(animated: true)
        return nil
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension EmptyRootNavigationController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissCallback?()
    }
}
