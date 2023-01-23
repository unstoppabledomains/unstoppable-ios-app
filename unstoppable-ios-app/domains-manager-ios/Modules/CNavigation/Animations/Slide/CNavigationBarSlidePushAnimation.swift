//
//  NavigationBarSlidePushAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

final class CNavigationBarSlidePushAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var animator: UIViewPropertyAnimator?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        buildTransitionAnimator(using: transitionContext)?.startAnimation()
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        buildTransitionAnimator(using: transitionContext)!
    }
    
    func buildTransitionAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating? {
        if let animator = animator {
            return animator
        }

        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let nav = fromViewController.cNavigationController
               else { return nil }
        
        let navBar = nav.navigationBar!
        let navBarSnapshot = UIImageView(frame: navBar.frame)
        navBarSnapshot.image = navBar.renderedImage()
        let containerView = transitionContext.containerView
        navBar.superview?.addSubview(navBarSnapshot)
        
        let fromNavChild = fromViewController as? CNavigationControllerChild
        let toNavChild = toViewController as? CNavigationControllerChild

        let backTitle = navBar.backButton.label.text
        let isBackHidden = navBar.backButton.alpha == 0
        navBar.setupWith(child: toNavChild, navigationItem: toViewController.navigationItem)
        navBar.setBackButton(title: fromViewController.title ?? "Back")
        navBar.setBackButton(hidden: false)
        
        navBar.frame.origin.x = containerView.bounds.width
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              curve: .easeOut) {
            navBar.frame.origin.x = 0
            navBarSnapshot.frame.origin.x = -containerView.frame.size.width
        }
        animator.addCompletion { position in
            navBar.frame.origin = .zero
            navBarSnapshot.removeFromSuperview()

            if position == .start {
                navBar.setBackButton(title: backTitle ?? "")
                navBar.setBackButton(hidden: isBackHidden)
                navBar.setupWith(child: fromNavChild, navigationItem: fromViewController.navigationItem)
            }
        }
        
        self.animator = animator
        return animator
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        animator = nil
    }
}
