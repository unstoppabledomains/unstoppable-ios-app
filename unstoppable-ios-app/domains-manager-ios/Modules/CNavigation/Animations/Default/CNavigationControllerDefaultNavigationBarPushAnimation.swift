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
        let fromNavChild = fromViewController.cNavigationControllerChild
        let toNavChild = toViewController.cNavigationControllerChild
        let isBackButtonHidden = navBar.backButton.alpha == 0
        let toYOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        let duration = transitionDuration(using: transitionContext)
        
        if let cNav = toViewController as? CNavigationController {
            cNav.navigationBar.setBackButton(hidden: true)
        }
        
        /// Back button
        let navBarBackButtonTransitionPerformer = NavBarBackButtonTransitionPerformer(navOperation: .push)
        navBarBackButtonTransitionPerformer.prepareForTransition(navBar: navBar,
                                                                 fromViewController: fromViewController,
                                                                 toViewController: toViewController)
        /// Nav items
        let navItemsTransitionPerformer = NavBarItemsTransitionPerformer()
        navItemsTransitionPerformer.setupWithCurrent(navBarContentView: navBar.navBarContentView)

        let navBarSnapshot = UIImageView(frame: navBar.frame)
        navBarSnapshot.image = navBar.toImageInWindowHierarchy()
        navBarSnapshot.frame = navBar.calculateFrameInWindow()
        navBar.window?.addSubview(navBarSnapshot)
        navBarBackButtonTransitionPerformer.addToWindow(navBar.window)

        navBar.setupWith(child: toNavChild, navigationItem: toViewController.navigationItem)
        CNavigationBarScrollingController().setYOffset(toYOffset, in: navBar)
        navItemsTransitionPerformer.setupWithNew(navBarContentView: navBar.navBarContentView)
        navItemsTransitionPerformer.addToWindow(navBar.window)
        navBar.frame.origin.x = containerView.bounds.width
        
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            navBar.frame.origin.x = 0
            navBarSnapshot.frame.origin.x = -(containerView.frame.size.width / 2)
        }

        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                    navBarSnapshot.alpha = 0
                }
            })
            
            navBarBackButtonTransitionPerformer.performAnimationsWith(duration: duration)
            navItemsTransitionPerformer.performAnimationsWith(duration: duration)
        }
        
        animator.addCompletion { position in
            navBar.frame.origin = .zero
            navBarSnapshot.removeFromSuperview()
            navBarBackButtonTransitionPerformer.finishTransition(isFinished: position == .end)
            navItemsTransitionPerformer.finishTransition(isFinished: position == .end)
            
            if position == .start {
                navBar.setBackButton(hidden: isBackButtonHidden)
                navBar.setupWith(child: fromNavChild, navigationItem: fromViewController.navigationItem)
            } else {
                navBar.setBackButton(hidden: false)
                if let cNav = toViewController as? CNavigationController {
                    cNav.navigationBar.setBackButton(hidden: false)
                }
            }
        }
        
        return animator
    }
}
