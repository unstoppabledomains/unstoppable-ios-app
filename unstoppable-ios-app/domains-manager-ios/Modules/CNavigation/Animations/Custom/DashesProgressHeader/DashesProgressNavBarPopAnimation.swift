//
//  DashesProgressNavBarPopAnimation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.08.2022.
//

import UIKit

final class DashesProgressNavBarPopAnimation: CBaseTransitioningAnimation {
    
    private let toProgress: CGFloat
    private let toConfiguration: DashesProgressView.Configuration

    init(animationDuration: TimeInterval,
         toProgress: Double,
         toConfiguration: DashesProgressView.Configuration) {
        self.toProgress = CGFloat(toProgress)
        self.toConfiguration = toConfiguration
        super.init(animationDuration: animationDuration)
    }
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let navBar = fromViewController.cNavigationController?.navigationBar,
              let dashesView = navBar.navBarContentView.titleView as? DashesProgressView,
              let toNavBarCopy = try? CNavigationHelper.makeCopy(of: navBar) else { return nil }
                
        let toNavChild = toViewController as? CNavigationControllerChild
        let yOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        
        toNavBarCopy.setupWith(child: toNavChild,
                               navigationItem: UINavigationItem(title: toViewController.navigationItem.title ?? ""))
        toNavBarCopy.setYOffset(yOffset)
        let largeTitleCopy = toNavBarCopy.largeTitleLabel!
        let isLargeTitleHidden = CNavigationBarScrollingController().isLargeTitleHidden(largeTitleCopy,
                                                                                        in: toNavBarCopy,
                                                                                        yOffset: yOffset)
        largeTitleCopy.isHidden = isLargeTitleHidden
        largeTitleCopy.alpha = 1
        largeTitleCopy.frame.origin.y += navBar.navBarBlur.bounds.height
        toViewController.view.addSubview(largeTitleCopy)
        
        let contentOffset = (toViewController as? CNavigationControllerChild)?.scrollableContentYOffset ?? 0
        let isBlurActive = yOffset >= contentOffset && contentOffset != 0
        
        
        let largeTitleView = navBar.largeTitleView!
        let fromProgress: CGFloat = dashesView.progress
        let toProgress: CGFloat = self.toProgress
        let toConfiguration = self.toConfiguration
        let duration = transitionDuration(using: transitionContext)
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            dashesView.setProgress(toProgress)
            dashesView.setWith(configuration: toConfiguration)
            largeTitleView.frame.origin.x += navBar.bounds.width
        }
        
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                    navBar.navBarBlur.alpha = isBlurActive ? 1 : 0
                    navBar.divider.alpha = isBlurActive ? 1 : 0
                }
            })
        }
        
        animator.addCompletion { position in
            if position == .start {
                dashesView.setProgress(fromProgress)
            } else {
                (toViewController.navigationItem.titleView as? DashesProgressView)?.setProgress(toProgress)
            }
            largeTitleView.frame.origin.x = 0
            largeTitleCopy.removeFromSuperview()
        }
        
        return animator
    }
    
}
