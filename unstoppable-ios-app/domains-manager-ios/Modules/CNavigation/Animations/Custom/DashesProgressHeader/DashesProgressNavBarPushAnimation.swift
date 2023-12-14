//
//  DashesProgressNavBarPushAnimation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.08.2022.
//

import UIKit

final class DashesProgressNavBarPushAnimation: CBaseTransitioningAnimation {
    
    private let toProgress: CGFloat?
    private let toConfiguration: DashesProgressView.Configuration?
    
    init(animationDuration: TimeInterval,
         toProgress: Double?,
         toConfiguration: DashesProgressView.Configuration?) {
        if let toProgress {
            self.toProgress = CGFloat(toProgress)
        } else {
            self.toProgress = nil
        }
        self.toConfiguration = toConfiguration
        super.init(animationDuration: animationDuration)
    }
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let navBar = fromViewController.cNavigationController?.navigationBar,
              let dashesView = navBar.navBarContentView.titleView as? DashesProgressView,
              let toNavBarCopy = try? CNavigationHelper.makeCopy(of: navBar) else { return nil }
        
        let fromLargeTitleCopy = CNavigationHelper.makeEfficientCopy(of: navBar.largeTitleLabel)
        let toNavChild = toViewController as? CNavigationControllerChild
        let yOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        
        // To nav large view copy
        toViewController.view.addSubview(toNavBarCopy)
        toNavBarCopy.setupWith(child: toNavChild,
                               navigationItem: UINavigationItem(title: toViewController.navigationItem.title ?? ""))
        toNavBarCopy.setYOffset(yOffset)
        toNavBarCopy.removeFromSuperview()
        toNavBarCopy.largeTitleLabel.alpha = 1
        let largeTitleViewCopy = toNavBarCopy.largeTitleView!
        toViewController.view.addSubview(largeTitleViewCopy)
        
        // From large title copy
        navBar.largeTitleLabel.isHidden = true
        fromLargeTitleCopy.frame.origin.y += navBar.navBarBlur.bounds.height
        fromViewController.view.addSubview(fromLargeTitleCopy)
        
        let toProgress: CGFloat? = self.toProgress
        let toConfiguration = self.toConfiguration
        let duration = transitionDuration(using: transitionContext)
        let start = Date()
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            if let toProgress {
                dashesView.setProgress(toProgress)
                dashesView.alpha = 1
            } else {
                dashesView.alpha = 0
            }
            if let toConfiguration {
                dashesView.setWith(configuration: toConfiguration)
            }
        }
        
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.3) {
                    navBar.navBarBlur.alpha = 0
                    navBar.divider.alpha = 0
                }
            })
        }
        
        animator.addCompletion { position in
            navBar.largeTitleLabel.isHidden = false
            if Date().timeIntervalSince(start) < duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    largeTitleViewCopy.removeFromSuperview()
                    fromLargeTitleCopy.removeFromSuperview()
                }
            } else {
                largeTitleViewCopy.removeFromSuperview()
                fromLargeTitleCopy.removeFromSuperview()
            }
        }
        
        return animator
    }
    
}

