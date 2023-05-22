//
//  NavBarBackButtonTransitionPerformer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.05.2023.
//

import UIKit

final class NavBarBackButtonTransitionPerformer {
  
    let navOperation: NavigationOperation
    private var isBackButtonHidden: Bool = false
    private var navBackButtonSnapshot: UIView?
    
    init(navOperation: NavBarBackButtonTransitionPerformer.NavigationOperation) {
        self.navOperation = navOperation
    }
    
    func prepareForTransition(navBar: CNavigationBar,
                              fromViewController: UIViewController,
                              toViewController: UIViewController) {
        let navBackButtonSnapshot: UIView
        
        switch navOperation {
        case .push:
            isBackButtonHidden = navBar.backButton.alpha == 0
            navBar.setBackButton(hidden: false)
            navBackButtonSnapshot = navBar.navBarContentView.backButton.renderedImageView()
            navBar.setBackButton(hidden: true)
            if isBackButtonHidden {
                navBackButtonSnapshot.alpha = 0
            }
        case .pop:
            isBackButtonHidden = toViewController == fromViewController.cNavigationController?.rootViewController
            navBackButtonSnapshot = navBar.navBarContentView.backButton.renderedImageView()
            
            if let cNav = fromViewController as? CNavigationController {
                cNav.navigationBar.setBackButton(hidden: true)
            }
        }
        
        self.navBackButtonSnapshot = navBackButtonSnapshot
        navBackButtonSnapshot.frame = navBar.navBarContentView.backButton.calculateFrameInWindow()
    }
    
    func addToWindow(_ window: UIWindow?) {
        guard let navBackButtonSnapshot else { return }
        
        window?.addSubview(navBackButtonSnapshot)
    }
    
    func performAnimationsWith(duration: TimeInterval) {
        UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
            switch self.navOperation {
            case .push:
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                    self.navBackButtonSnapshot?.alpha = 1
                }
            case .pop:
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                    if self.isBackButtonHidden {
                        self.navBackButtonSnapshot?.alpha = 0
                    }
                }
            }
        })
    }
    
    func finishTransition(isFinished: Bool) {
        navBackButtonSnapshot?.removeFromSuperview()
    }
}

// MARK: - Open methods
extension NavBarBackButtonTransitionPerformer {
    enum NavigationOperation {
        case push, pop
    }
}
