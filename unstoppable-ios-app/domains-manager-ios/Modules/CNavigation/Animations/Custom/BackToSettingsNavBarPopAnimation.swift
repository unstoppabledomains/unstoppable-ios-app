//
//  BackToSettingsNavBarPopAnimation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.08.2022.
//

import UIKit

final class BackToSettingsNavBarPopAnimation: CBaseTransitioningAnimation {
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {

        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let navBar = fromViewController.cNavigationController?.navigationBar,
              let navBarContent = navBar.navBarContentView else { return nil }
        
        let largeTitle = navBar.largeTitleLabel!
        let largeTitleOrigin = CNavigationBar.Constants.largeTitleOrigin
        let largeTitleCopy = CNavigationHelper.makeEfficientCopy(of: largeTitle)
        
        navBar.addSubview(largeTitleCopy)
        navBar.bringSubviewToFront(navBar.navBarBlur)
        navBar.bringSubviewToFront(navBar.divider)
        navBar.bringSubviewToFront(navBar.navBarContentView)
        largeTitleCopy.text = toViewController.navigationItem.title
        largeTitleCopy.frame.origin = CGPoint(x: largeTitleOrigin.x,
                                              y: navBar.largeTitleView.frame.minY + largeTitleOrigin.y)
        let rightItem = navBarContent.rightBarViews.first
        let yOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        let isLargeTitleHidden = CNavigationBarScrollingController().isLargeTitleHidden(largeTitleCopy,
                                                                                        in: navBar,
                                                                                        yOffset: yOffset)
        largeTitleCopy.isHidden = isLargeTitleHidden
        largeTitleCopy.frame.origin.y -= yOffset
        let contentOffset = (toViewController as? CNavigationControllerChild)?.scrollableContentYOffset ?? 0
        let isBlurActive = yOffset >= contentOffset

        var titleCopy: UILabel?
        if isLargeTitleHidden {
            let titleLabelCopy = CNavigationHelper.makeEfficientCopy(of: navBar.titleLabel)
            navBar.addSubview(titleLabelCopy)
            titleLabelCopy.text = toViewController.title
            titleLabelCopy.alpha = 0
            titleLabelCopy.isHidden = false
            titleLabelCopy.sizeToFit()
            titleLabelCopy.center = CNavigationHelper.center(of: navBar.navBarContentView.bounds)
            titleLabelCopy.frame.origin.y += navBar.navBarContentView.frame.minY
            titleCopy = titleLabelCopy
        }
        
        let duration = transitionDuration(using: transitionContext)
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            navBarContent.titleLabel.frame.origin.x = navBarContent.bounds.width // Move title to the right
            navBar.titleLabel.alpha = 0
        } 
        
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                    rightItem?.alpha = 0 // Hide plus button
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.3) {
                    navBar.navBarBlur.alpha = isBlurActive ? 1 : 0
                    navBar.divider.alpha = isBlurActive ? 1 : 0
                }
            })
        }
        
        animator.addAnimations({
            largeTitleCopy.alpha = 1 // Show large title with fade effect
            titleCopy?.alpha = 1
        }, delayFactor: 0.1)
        
        animator.addCompletion { position in
            titleCopy?.removeFromSuperview()
            largeTitleCopy.removeFromSuperview()
        }
        
        return animator
    }
    
}
