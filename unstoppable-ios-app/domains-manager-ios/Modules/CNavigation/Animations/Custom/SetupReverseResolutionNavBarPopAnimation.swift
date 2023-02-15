//
//  SetupReverseResolutionNavBarPopAnimation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.09.2022.
//

import UIKit

final class SetupReverseResolutionNavBarPopAnimation: CBaseTransitioningAnimation {
        
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let navBar = fromViewController.cNavigationController?.navigationBar,
              let navBarContent = navBar.navBarContentView,
              let toNavBarCopy = try? CNavigationHelper.makeCopy(of: navBar) else { return nil }
        
        let toNavChild = toViewController as? CNavigationControllerChild
        let yOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        
        toNavBarCopy.setupWith(child: toNavChild,
                               navigationItem: UINavigationItem(title: toViewController.navigationItem.title ?? ""))
        toNavBarCopy.setYOffset(yOffset)
        let largeTitleCopy = toNavBarCopy.largeTitleLabel!
        let largeTitleImageView = toNavBarCopy.largeTitleImageView!
        largeTitleImageView.frame.origin.x = navBar.bounds.width / 2 - largeTitleImageView.bounds.width / 2
        let isLargeTitleHidden = CNavigationBarScrollingController().isLargeTitleHidden(largeTitleCopy,
                                                                                        in: toNavBarCopy,
                                                                                        yOffset: yOffset)
        
        [largeTitleCopy, largeTitleImageView].forEach { view in
            view.isHidden = isLargeTitleHidden
            view.alpha = 1
            view.frame.origin.y += navBar.navBarBlur.bounds.height
            toViewController.view.addSubview(view)
        }

        
        let contentOffset = (toViewController as? CNavigationControllerChild)?.scrollableContentYOffset ?? 0
        let isBlurActive = yOffset >= contentOffset && contentOffset != 0
        
        var backButtonTransitionImage: UIImageView?
        let currentBackButtonImage: UIImage? = navBarContent.backButton.icon.image
        let isBackButtonHidden = !(toViewController.cNavigationController is EmptyRootCNavigationController)
        if !isBackButtonHidden {
            backButtonTransitionImage = CNavigationHelper.makeEfficientCopy(of: navBarContent.backButton.icon)
            backButtonTransitionImage?.image = navBarContent.backButton.icon.image
            if let backButtonTransitionImage = backButtonTransitionImage {
                navBarContent.backButton.icon.alpha = 0
                navBarContent.backButton.icon.image = (toViewController as? BaseViewController)?.navBackStyle.icon
                navBarContent.backButton.addSubview(backButtonTransitionImage)
            }
        }
        
        let largeTitleView = navBar.largeTitleView!
        let duration = transitionDuration(using: transitionContext)
        let animator = UIViewPropertyAnimator(duration: duration,
                                              controlPoint1: CNavigationHelper.AnimationCurveControlPoint1,
                                              controlPoint2: CNavigationHelper.AnimationCurveControlPoint2) {
            largeTitleView.frame.origin.x += navBar.bounds.width
            if isBackButtonHidden {
                navBarContent.backButton.icon.alpha = 0
            }
        }
        
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    backButtonTransitionImage?.alpha = 0
                }
                
                if !isBackButtonHidden {
                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                        navBarContent.backButton.icon.alpha = 1
                    }
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                    navBar.navBarBlur.alpha = isBlurActive ? 1 : 0
                    navBar.divider.alpha = isBlurActive ? 1 : 0
                }
            })
        }
        
        animator.addCompletion { position in
            largeTitleView.frame.origin.x = 0
            largeTitleCopy.removeFromSuperview()
            largeTitleImageView.removeFromSuperview()
            backButtonTransitionImage?.removeFromSuperview()
            navBarContent.backButton.icon.image = currentBackButtonImage
            navBarContent.backButton.icon.alpha = 1
        }
        
        return animator
    }
    
}
