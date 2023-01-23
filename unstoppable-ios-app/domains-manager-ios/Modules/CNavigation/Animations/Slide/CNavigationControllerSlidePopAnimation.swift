//
//  NavigationControllerSlidePopAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

final class CNavigationControllerSlidePopAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var animator: UIViewPropertyAnimator?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        buildTransitionAnimator(using: transitionContext)?.startAnimation()
    }
    
    func buildTransitionAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating? {
        if let animator = animator {
            return animator
        }
        
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return nil }
        let containerView = transitionContext.containerView
        
        toViewController.view.frame = containerView.bounds.offsetBy(dx: -containerView.frame.size.width + 1, dy: 0.0)
        containerView.addSubview(toViewController.view)
        containerView.bringSubviewToFront(fromViewController.view)
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              curve: .easeOut) {
            fromViewController.view.frame = containerView.bounds.offsetBy(dx: containerView.frame.width, dy: 0)
            toViewController.view.frame = containerView.bounds
            fromViewController.navigationController?.navigationBar.layoutIfNeeded()
        }
        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        self.animator = animator
        
        return animator
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        buildTransitionAnimator(using: transitionContext)!
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        animator = nil
    }
}
