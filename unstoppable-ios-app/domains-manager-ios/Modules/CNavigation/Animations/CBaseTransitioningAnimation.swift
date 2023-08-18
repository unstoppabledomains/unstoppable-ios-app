//
//  BaseTransitioningAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 26.07.2022.
//

import UIKit

class CBaseTransitioningAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let animationDuration: TimeInterval
    private var animator: UIViewPropertyAnimator?
    
    init(animationDuration: TimeInterval) {
        self.animationDuration = animationDuration
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionAnimator(using: transitionContext)?.startAnimation()
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        transitionAnimator(using: transitionContext)!
    }
    
    func transitionAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating? {
        if let animator = animator {
            return animator
        }
        
        let animator = buildAnimator(using: transitionContext)
        
        self.animator = animator
        return animator
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        animator = nil
    }
    
    func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        fatalError("Should be overridden")
    }
    
    func createAnimatorIn(transitionContext: UIViewControllerContextTransitioning,
                          animationBlock: @escaping EmptyCallback) -> UIViewPropertyAnimator {
        let duration = transitionDuration(using: transitionContext)
        return UIViewPropertyAnimator(duration: duration,
                                      controlPoint1: CNavigationHelper.AnimationCurveControlPoint1,
                                      controlPoint2: CNavigationHelper.AnimationCurveControlPoint2) {
            animationBlock()
        }
    }
}
