//
//  NavigationControllerDefaultNavigationBarPopAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

final class CNavigationControllerDefaultNavigationBarPopAnimation: CBaseTransitioningAnimation {
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let nav = fromViewController.cNavigationController else { return nil }
      
        let navBar = nav.navigationBar!
        let fromIsTitleHidden = navBar.navBarContentView.isTitleViewHidden
        let fromYOffset = CNavigationHelper.contentYOffset(in: fromViewController.view)
        let fromBlurAlpha = navBar.navBarBlur.alpha
        let containerView = transitionContext.containerView
        let isLastViewController = toViewController == fromViewController.cNavigationController?.rootViewController
        let isBackButtonHidden = isLastViewController
        let fromNavChild = fromViewController.cNavigationControllerChild
        let toNavChild = toViewController.cNavigationControllerChild
        let toYOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        let contentOffset = (toViewController as? CNavigationControllerChild)?.scrollableContentYOffset ?? 0
        let isBlurActive = toYOffset > contentOffset
        let duration = transitionDuration(using: transitionContext)

        
        /// Back button
        let navBarBackButtonTransitionPerformer = NavBarBackButtonTransitionPerformer(navOperation: .pop)
        navBarBackButtonTransitionPerformer.prepareForTransition(navBar: navBar,
                                                                 fromViewController: fromViewController,
                                                                 toViewController: toViewController)
        
        let navItemsTransitionPerformer = NavBarItemsTransitionPerformer()
        navItemsTransitionPerformer.setupWithCurrent(navBarContentView: navBar.navBarContentView)
        
        navBar.setBackButton(hidden: true)
        let navBarSnapshot = UIImageView(frame: navBar.frame)
        navBarSnapshot.image = navBar.toImageInWindowHierarchy()
        navBarSnapshot.frame = navBar.calculateFrameInWindow()
        navBar.window?.addSubview(navBarSnapshot)
        navBarBackButtonTransitionPerformer.addToWindow(navBar.window)

        navBar.setupWith(child: toNavChild, navigationItem: toViewController.navigationItem)
        navBar.navBarContentView.setTitleView(hidden: toViewController.navigationItem.titleView?.alpha == 0, animated: false)
        CNavigationBarScrollingController().setYOffset(toYOffset, in: navBar)
        navItemsTransitionPerformer.setupWithNew(navBarContentView: navBar.navBarContentView)
        navItemsTransitionPerformer.addToWindow(navBar.window)
        navBar.navBarBlur.alpha = isBlurActive ? 1 : 0
        navBar.divider.alpha = isBlurActive ? 1 : 0
        navBar.frame.origin.x = -containerView.bounds.width
        
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            navBar.frame.origin.x = 0
            navBarSnapshot.frame.origin.x = containerView.frame.width
        }
        
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                  
                }
            })
            
            navBarBackButtonTransitionPerformer.performAnimationsWith(duration: duration)
            navItemsTransitionPerformer.performAnimationsWith(duration: duration)
        }
        
        animator.addCompletion { position in
            UIView.performWithoutAnimation {
                navBar.frame.origin = .zero
                navBarSnapshot.removeFromSuperview()
                navBarBackButtonTransitionPerformer.finishTransition(isFinished: position == .end)
                navItemsTransitionPerformer.finishTransition(isFinished: position == .end)

                if position == .end {
                    CNavigationBarScrollingController().setYOffset(toYOffset, in: navBar)
                    navBar.setBackButton(hidden: isBackButtonHidden)
                } else {
                    navBar.setupWith(child: fromNavChild, navigationItem: fromViewController.navigationItem)
                    navBar.setBackButton(hidden: false)
                    if let cNav = fromViewController as? CNavigationController {
                        cNav.navigationBar.setBackButton(hidden: false)
                    }
                    navBar.navBarContentView.setTitleView(hidden: fromIsTitleHidden, animated: false)
                    CNavigationBarScrollingController().setYOffset(fromYOffset, in: navBar)
                    navBar.navBarBlur.alpha = fromBlurAlpha
                    navBar.divider.alpha = fromBlurAlpha
                }
            }
        }
        
        return animator
    }
}
