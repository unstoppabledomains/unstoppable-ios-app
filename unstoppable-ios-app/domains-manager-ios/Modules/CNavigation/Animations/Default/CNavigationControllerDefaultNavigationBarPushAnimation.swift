//
//  NavigationControllerDefaultNavigationBarPushAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

final class CNavigationControllerDefaultNavigationBarPushAnimation: CBaseTransitioningAnimation {
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let nav = fromViewController.cNavigationController
        else { return nil }
        
        let navBar = nav.navigationBar!
        let containerView = transitionContext.containerView
        let fromNavChild = fromViewController as? CNavigationControllerChild
        let toNavChild = toViewController as? CNavigationControllerChild
        let isBackButtonHidden = navBar.backButton.alpha == 0
        let toYOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        let duration = transitionDuration(using: transitionContext)
        
        /// Back button logic
        navBar.setBackButton(hidden: false)
        let navBackButtonSnapshot = navBar.navBarContentView.backButton.renderedImageView()
        navBackButtonSnapshot.frame = navBar.navBarContentView.backButton.calculateFrameInWindow()
        navBar.setBackButton(hidden: true)
        if isBackButtonHidden {
            navBackButtonSnapshot.alpha = 0
        }
        
        let navBarSnapshot = UIImageView(frame: navBar.frame)
        navBarSnapshot.image = navBar.toImageInWindowHierarchy()
        navBarSnapshot.frame = navBar.calculateFrameInWindow()
        navBar.window?.addSubview(navBarSnapshot)
        navBar.window?.addSubview(navBackButtonSnapshot)

        navBar.setupWith(child: toNavChild, navigationItem: toViewController.navigationItem)
        CNavigationBarScrollingController().setYOffset(toYOffset, in: navBar)
        navBar.frame.origin.x = containerView.bounds.width
        
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            navBar.frame.origin.x = 0
            navBarSnapshot.frame.origin.x = -(containerView.frame.size.width / 2)
        }

        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.8) {
                    navBarSnapshot.alpha = 0
                }
                
                /// Back button logic
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                    navBackButtonSnapshot.alpha = 1
                }
            })
        }
        
        animator.addCompletion { position in
            navBar.frame.origin = .zero
            navBarSnapshot.removeFromSuperview()
            navBackButtonSnapshot.removeFromSuperview()
            
            if position == .start {
                navBar.setBackButton(hidden: isBackButtonHidden)
                navBar.setupWith(child: fromNavChild, navigationItem: fromViewController.navigationItem)
            } else {
                navBar.setBackButton(hidden: false)                
            }
        }
        
        return animator
    }
}
