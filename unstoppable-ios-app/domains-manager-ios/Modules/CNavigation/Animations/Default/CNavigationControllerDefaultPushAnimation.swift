//
//  NavigationControllerDefaultPushAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 24.07.2022.
//

import UIKit

final class CNavigationControllerDefaultPushAnimation: CBaseTransitioningAnimation {
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return nil }
        let containerView = transitionContext.containerView
        
        toViewController.view.frame = containerView.bounds.offsetBy(dx: containerView.frame.size.width, dy: 0.0)
        containerView.addSubview(toViewController.view)
        
        // Fade view
        let fadeView = UIView(frame: fromViewController.view.bounds)
        fadeView.alpha = 0
        fadeView.backgroundColor = .black.withAlphaComponent(0.2)
        fromViewController.view.addSubview(fadeView)
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              controlPoint1: CNavigationHelper.AnimationCurveControlPoint1,
                                              controlPoint2: CNavigationHelper.AnimationCurveControlPoint2) {
            toViewController.view.frame = containerView.bounds
            fromViewController.view.frame = containerView.bounds.offsetBy(dx: -containerView.frame.size.width * 0.3, dy: 0)
            fadeView.alpha = 1
        }
        
        animator.addCompletion { _ in
            fadeView.removeFromSuperview()
            fromViewController.view.frame.origin.x = 0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        return animator
    }
    
}
