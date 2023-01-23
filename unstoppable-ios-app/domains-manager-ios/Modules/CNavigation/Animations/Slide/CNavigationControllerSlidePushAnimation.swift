//
//  NavigationControllerSlidePushAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

final class CNavigationControllerSlidePushAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
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
              let toViewController = transitionContext.viewController(forKey: .to) else { return nil }
        let containerView = transitionContext.containerView
        
        toViewController.view.frame = containerView.bounds.offsetBy(dx: containerView.frame.size.width, dy: 0.0)
        containerView.addSubview(toViewController.view)
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              curve: .easeOut) {
            toViewController.view.frame = containerView.bounds
            fromViewController.view.frame = containerView.bounds.offsetBy(dx: -containerView.frame.size.width, dy: 0)
        }
        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        self.animator = animator
        return animator
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        animator = nil
    }
}
