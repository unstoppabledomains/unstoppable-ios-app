//
//  NavigationControllerDefaultPopAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 24.07.2022.
//

import UIKit

final class CNavigationControllerDefaultPopAnimation: CBaseTransitioningAnimation {
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return nil }
        let containerView = transitionContext.containerView
        
        toViewController.view.frame = containerView.bounds.offsetBy(dx: -containerView.frame.size.width * 0.3, dy: 0.0)
        containerView.addSubview(toViewController.view)
        containerView.bringSubviewToFront(fromViewController.view)
        
        // Fade view
        let fadeView = UIView(frame: toViewController.view.bounds)
        fadeView.backgroundColor = .black.withAlphaComponent(0.2)
        toViewController.view.addSubview(fadeView)
        
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            fromViewController.view.frame = containerView.bounds.offsetBy(dx: containerView.frame.width, dy: 0)
            toViewController.view.frame = containerView.bounds
            fromViewController.navigationController?.navigationBar.layoutIfNeeded()
            fadeView.alpha = 0
        }
        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            fadeView.removeFromSuperview()
        }
        
        return animator
    }
}
