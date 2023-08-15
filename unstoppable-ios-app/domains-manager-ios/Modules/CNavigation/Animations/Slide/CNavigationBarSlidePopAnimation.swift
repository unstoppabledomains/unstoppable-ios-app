//
//  NavigationBarSlidePopAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

final class CNavigationBarSlidePopAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
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
              let toViewController = transitionContext.viewController(forKey: .to),
              let nav = fromViewController.cNavigationController,
              let toNavBarCopy = try? CNavigationHelper.makeCopy(of: nav.navigationBar) else { return nil }
        let navBar = nav.navigationBar!
        let containerView = transitionContext.containerView
        navBar.superview?.addSubview(toNavBarCopy)
        
        let toNavChild = toViewController as? CNavigationControllerChild
        
        toNavBarCopy.setNeedsLayout()
        toNavBarCopy.layoutIfNeeded()
        toNavBarCopy.setupWith(child: toNavChild, navigationItem: toViewController.navigationItem)

        let isLastViewController = toViewController == fromViewController.cNavigationController?.rootViewController
        var newBackButtonTitle: String?
        
        if !isLastViewController,
           let nav = fromViewController.cNavigationController,
           let i = nav.viewControllers.firstIndex(of: toViewController),
           i > 0 {
            newBackButtonTitle = nav.viewControllers[i-1].title
        }
        
        toNavBarCopy.setBackButton(title: newBackButtonTitle ?? "")
        toNavBarCopy.setBackButton(hidden: isLastViewController)
        toNavBarCopy.navBarContentView.setTitleView(hidden: navBar.navBarContentView.isTitleViewHidden, animated: false)
        let toYOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        toNavBarCopy.setYOffset(toYOffset)
        toNavBarCopy.frame.origin.x = -containerView.bounds.width
        
        let contentOffset = (toViewController as? CNavigationControllerChild)?.scrollableContentYOffset ?? 0
        let isBlurActive = toYOffset >= contentOffset
        UIView.performWithoutAnimation {
            toNavBarCopy.setBlur(hidden: !isBlurActive, animated: false)
            toNavBarCopy.divider.alpha = isBlurActive ? 1 : 0
        }
        
        let duration = transitionDuration(using: transitionContext)
        let animator = UIViewPropertyAnimator(duration: duration,
                                              curve: .easeOut) {
            toNavBarCopy.frame.origin.x = 0
            navBar.frame.origin.x = containerView.frame.size.width
        }
        
        animator.addCompletion { position in
            UIView.performWithoutAnimation {
                navBar.frame.origin = .zero
                toNavBarCopy.removeFromSuperview()
                if position == .end {
                    navBar.setBackButton(title: newBackButtonTitle ?? "")
                    CNavigationBarScrollingController().setYOffset(toYOffset, in: navBar)
                }
            }
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

