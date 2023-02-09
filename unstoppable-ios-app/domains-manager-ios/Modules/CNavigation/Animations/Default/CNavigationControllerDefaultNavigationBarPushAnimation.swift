//
//  NavigationControllerDefaultNavigationBarPushAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

final class CNavigationControllerDefaultNavigationBarPushAnimation: CBaseTransitioningAnimation {
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let navBar = fromViewController.cNavigationController?.navigationBar,
              let navBarContent = navBar.navBarContentView else { return nil }
        
        let currentBackButtonTitle = navBarContent.backButton.label.text
        let backButtonTitle = fromViewController.title ?? navBarContent.defaultBackButtonTitle
        let newTitle = toViewController.title
        let backButtonFrame = navBarContent.backButton.label.frame
        
        // Buck button mask
        let maskView = UIView(frame: navBarContent.backButton.label.bounds)
        maskView.backgroundColor = .systemBlue
        navBarContent.backButton.label.mask = maskView
        
        let toNavChild = toViewController as? CNavigationControllerChild
        let fromNavChild = fromViewController as? CNavigationControllerChild
        
        // Type of transition
        let toPreferLarge = toNavChild?.prefersLargeTitles ?? false
        let fromPreferLarge = fromNavChild?.prefersLargeTitles ?? false
        let yOffset = CNavigationHelper.contentYOffset(in: fromViewController.view)
        let isLargeTitleCollapsed = CNavigationBarScrollingController().isLargeTitleHidden(navBar.largeTitleLabel,
                                                                                           in: navBar,
                                                                                           yOffset: yOffset)
        let toYOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        let contentOffset = (toViewController as? CNavigationControllerChild)?.scrollableContentYOffset ?? 0
        let isBlurActive = toYOffset > contentOffset
        
        let oldNavComponents = CNavComponents(viewController: fromViewController)
        let newNavComponents = CNavComponents(viewController: toViewController)
        let backTitleVisible = toNavChild?.navBackButtonConfiguration.backTitleVisible ?? true
        let largeTitleConfiguration = toNavChild?.largeTitleConfiguration

        let titleTransitioning: CNavBarTitleTransitioning
        let backButtonTransitioning: CNavBarTitleTransitioning
        switch (fromPreferLarge, toPreferLarge) {
        case (false, false):
            backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, backButtonTitle: backButtonTitle, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
            titleTransitioning = TitleTransitioningSmallToSmall(navBar: navBarContent, newTitle: newTitle, newNavComponents: newNavComponents)!
        case (false, true):
            backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, backButtonTitle: backButtonTitle, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
            titleTransitioning = TitleTransitioningSmallToLarge(navBar: navBar,
                                                                newTitle: newTitle,
                                                                largeTitleConfiguration: largeTitleConfiguration,
                                                                attributes: toNavChild?.largeTitleConfiguration?.navBarLargeTitleAttributes ?? navBar.largeTitleAttributes)!
        case (true, false):
            if isLargeTitleCollapsed {
                backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, backButtonTitle: backButtonTitle, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
                titleTransitioning = TitleTransitioningSmallToSmall(navBar: navBarContent, newTitle: newTitle, newNavComponents: newNavComponents)!
            } else {
                backButtonTransitioning = BackButtonTransitioningLargeToLarge(navBar: navBar, newTitle: newTitle, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents, backTitleVisible: backTitleVisible)!
                titleTransitioning = TitleTransitioningLargeToSmall(navBar: navBar, newTitle: newTitle, newNavComponents: newNavComponents)!
            }
        case (true, true):
            if isLargeTitleCollapsed {
                backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, backButtonTitle: backButtonTitle, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
                titleTransitioning = TitleTransitioningSmallToSmall(navBar: navBarContent, newTitle: newTitle, newNavComponents: newNavComponents)!
            } else {
                backButtonTransitioning = BackButtonTransitioningLargeToLarge(navBar: navBar, newTitle: newTitle, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents, backTitleVisible: backTitleVisible)!
                titleTransitioning = TitleTransitioningLargeToLarge(navBar: navBar, newTitle: newTitle)!
            }
        }
        
        // isHidden
        let toIsHidden = toNavChild?.isNavBarHidden ?? false || toViewController is CNavigationController
        let fromIsHidden = fromNavChild?.isNavBarHidden ?? false || fromViewController is CNavigationController
        var navBarVisibilityTransitioning: CNavBarTitleTransitioning?
    
        if toIsHidden != fromIsHidden {
            navBarVisibilityTransitioning = CNavBarHideTransitioning(navBar: navBar, willHide: toIsHidden)
        }

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              controlPoint1: CNavigationHelper.AnimationCurveControlPoint1,
                                              controlPoint2: CNavigationHelper.AnimationCurveControlPoint2)
        
        animator.addAnimations {
            navBarContent.setBackButton(hidden: false)
            navBarContent.backButtonConfiguration = toNavChild?.navBackButtonConfiguration ?? .default
            navBarContent.backButton.label.alpha = 0
            navBarContent.backButton.label.frame.origin.x = -backButtonFrame.width
            maskView.frame.origin.x += backButtonFrame.width
            navBar.navBarBlur.alpha = isBlurActive ? 1 : 0
            navBar.divider.alpha = isBlurActive ? 1 : 0
            
            navBarVisibilityTransitioning?.addAnimations()
            backButtonTransitioning.addAnimations()
            titleTransitioning.addAnimations()
        }
        
        navBarVisibilityTransitioning?.addAdditionalAnimation(in: animator, duration: self.transitionDuration(using: transitionContext))
        titleTransitioning.addAdditionalAnimation(in: animator, duration: self.transitionDuration(using: transitionContext))
        backButtonTransitioning.addAdditionalAnimation(in: animator, duration: self.transitionDuration(using: transitionContext))
        
        animator.addCompletion { position in
            navBarContent.backButton.label.alpha = 1
            navBarContent.backButton.label.mask =  nil
            maskView.removeFromSuperview()
            navBarContent.setBackButton(title: backButtonTitle)
            
            titleTransitioning.completionAction(position: position)
            backButtonTransitioning.completionAction(position: position)
            navBarVisibilityTransitioning?.completionAction(position: position)
            
            if position == .start {
                navBar.set(title: fromViewController.title)
                navBar.setBackButton(title: currentBackButtonTitle ?? "")
                navBarContent.backButtonConfiguration = fromNavChild?.navBackButtonConfiguration ?? .default
            }
        }
        
        return animator
    }
    
}

private struct TitleTransitioningSmallToSmall: CNavBarTitleTransitioning {
    
    private let transitionFromTitle: UILabel
    private let titleView: UIView?
    private let titleLabel: UILabel
    private let targetX: CGFloat
    private let targetTitleCenter: CGPoint
    private let hasTitleView: Bool
    private let currentTitleLabelAlpha: CGFloat
    private let currentTitleViewAlpha: CGFloat?
    
    init?(navBar: CNavigationBarContentView,
          newTitle: String?,
          newNavComponents: CNavComponents) {
        guard let transitionFromTitle = try? CNavigationHelper.makeCopy(of: navBar.titleLabel) else { return nil }
        
        self.hasTitleView = newNavComponents.titleView != nil
        self.transitionFromTitle = transitionFromTitle
        titleLabel = navBar.titleLabel!
        titleView = navBar.titleView
        currentTitleLabelAlpha = titleLabel.alpha
        currentTitleViewAlpha = navBar.titleView?.alpha
        targetX = navBar.backButton.label.frame.minX
        targetTitleCenter = titleLabel.center
        
        navBar.addSubview(transitionFromTitle)
        navBar.set(title: newTitle)
        titleLabel.alpha = 0
        titleLabel.frame.origin.x = navBar.bounds.width
    }
    
    func addAnimations() {
        transitionFromTitle.frame.origin.x = targetX
        titleLabel.center = targetTitleCenter
        if !hasTitleView {
            titleLabel.alpha = 1
        }
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    transitionFromTitle.alpha = 0
                }
            })
        }
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        if position == .start {
            titleLabel.alpha = currentTitleLabelAlpha
        } else {
            if !hasTitleView {
                titleLabel.alpha = 1
            }
        }
        if let currentTitleViewAlpha {
            titleView?.alpha = currentTitleViewAlpha
        }
        transitionFromTitle.removeFromSuperview()
    }
}

private struct TitleTransitioningSmallToLarge: CNavBarTitleTransitioning {
    
    private let transitionFromTitle: UIView
    private let transitionNewLargeTitle: UILabel
    private var transitionNewLargeImage: UIImageView?
    private let titleLabel: UIView
    private let titleView: UIView?
    private let largeTitleLabel: UILabel
    
    private let targetTitleX: CGFloat
    private var targetTitleImageX: CGFloat?
    private let targetX: CGFloat
    private let backButtonX: CGFloat
    private let currentTitleViewAlpha: CGFloat?
    private let searchBarView: UIView?
    private let searchBarViewTargetX: CGFloat

    init?(navBar: CNavigationBar,
          newTitle: String?,
          largeTitleConfiguration: CNavigationBar.LargeTitleConfiguration?,
          attributes: [NSAttributedString.Key : Any]) {
        guard let transitionNewLargeTitle = try? CNavigationHelper.makeCopy(of: navBar.largeTitleLabel),
              let transitionFromTitle = try? CNavigationHelper.makeCopy(of: navBar.titleLabel) else { return nil }
        
        navBar.addSubview(transitionNewLargeTitle)
        if let newTitle = newTitle {
            transitionNewLargeTitle.attributedText = NSAttributedString(string: newTitle, attributes: attributes)
        } else {
            transitionNewLargeTitle.attributedText = nil
        }
        transitionNewLargeTitle.frame.size = CNavigationHelper.sizeOf(label: transitionNewLargeTitle,
                                                                      withConstrainedSize: navBar.largeTitleView.bounds.size)
        transitionNewLargeTitle.frame.origin.x = navBar.bounds.width
        transitionNewLargeTitle.frame.origin.y = navBar.largeTitleView.frame.minY + CNavigationBar.Constants.largeTitleOrigin.y
        if largeTitleConfiguration?.largeTitleIcon != nil {
            transitionNewLargeTitle.frame.origin.y += (largeTitleConfiguration?.largeTitleIconSize?.height ?? CNavigationBar.Constants.largeTitleIconSize.height) + CNavigationBar.Constants.largeTitleIconOffset
        }
        
        self.transitionNewLargeTitle = transitionNewLargeTitle
        transitionNewLargeTitle.alpha = 1
        navBar.navBarContentView.addSubview(transitionFromTitle)
        self.transitionFromTitle = transitionFromTitle
        
        navBar.set(title: newTitle)
        
        targetTitleX = navBar.backButton.label.frame.minX
        
        if transitionNewLargeTitle.textAlignment == .center {
            targetX = (navBar.bounds.width / 2) - (transitionNewLargeTitle.bounds.width / 2)
        } else {
            targetX = CNavigationBar.Constants.largeTitleOrigin.x
        }
        
        if let image = largeTitleConfiguration?.largeTitleIcon {
            let size = largeTitleConfiguration?.largeTitleIconSize ?? CNavigationBar.Constants.largeTitleIconSize
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: size))
            imageView.image = image
            self.transitionNewLargeImage = imageView
            navBar.largeTitleView.addSubview(imageView)
            
            
            targetTitleImageX = navBar.navBarContentView.bounds.width / 2 - size.width / 2
            imageView.frame.origin.x = navBar.bounds.width
            imageView.frame.origin.y = CNavigationBar.Constants.largeTitleOrigin.y
        }
        
        searchBarView = navBar.navBarContentView.searchBarConfiguration?.searchBarView
        searchBarViewTargetX = -navBar.bounds.width
        
        titleLabel = navBar.titleLabel
        titleView = navBar.navBarContentView.titleView
        currentTitleViewAlpha = navBar.navBarContentView.titleView?.alpha
        largeTitleLabel = navBar.largeTitleLabel
        backButtonX = navBar.backButton.label.frame.minX
        titleLabel.alpha = 0
    }
    
    func addAnimations() {
        transitionNewLargeTitle.frame.origin.x = targetX
        titleLabel.alpha = 0
        titleLabel.frame.origin.x = backButtonX
        transitionFromTitle.frame.origin.x = targetTitleX
        transitionNewLargeImage?.frame.origin.x = targetTitleImageX ?? 0
        searchBarView?.frame.origin.x = searchBarViewTargetX
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    transitionFromTitle.alpha = 0
                }
            })
        }
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        if position == .start {
            titleLabel.alpha = 1
            largeTitleLabel.alpha = 0
        } else {
            largeTitleLabel.alpha = 1
            largeTitleLabel.superview?.isHidden = false
        }
        if let currentTitleViewAlpha {
            titleView?.alpha = currentTitleViewAlpha
        }
        transitionNewLargeTitle.removeFromSuperview()
        transitionFromTitle.removeFromSuperview()
        transitionNewLargeImage?.removeFromSuperview()
    }
}

private struct TitleTransitioningLargeToSmall: CNavBarTitleTransitioning {
    
    private let transitionLargeTitle: UILabel
    private let titleLabel: UIView
    private let largeTitleImageView: UIView
    private let largeTitleLabel: UILabel
    private let targetTitleCenter: CGPoint
    private let hasTitleView: Bool

    init?(navBar: CNavigationBar,
          newTitle: String?,
          newNavComponents: CNavComponents) {
        guard let transitionLargeTitle = try? CNavigationHelper.makeCopy(of: navBar.largeTitleLabel) else { return nil }
        
        self.hasTitleView = newNavComponents.titleView != nil
        navBar.addSubview(transitionLargeTitle)
        transitionLargeTitle.frame.origin.x = navBar.largeTitleLabel.frame.minX
        transitionLargeTitle.frame.origin.y = navBar.largeTitleView.frame.minY + navBar.largeTitleLabel.frame.minY
        self.transitionLargeTitle = transitionLargeTitle
        
        self.largeTitleImageView = navBar.largeTitleImageView
        
        titleLabel = navBar.titleLabel
        largeTitleLabel = navBar.largeTitleLabel

        largeTitleLabel.alpha = 0
        navBar.set(title: newTitle)
        targetTitleCenter = titleLabel.center
        titleLabel.frame.origin.x = navBar.bounds.width
    }
    
    func addAnimations() {
        transitionLargeTitle.alpha = 0
        largeTitleImageView.alpha = 0
        if !hasTitleView {
            titleLabel.alpha = 1
        }
        titleLabel.center = targetTitleCenter
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) { }
    
    func completionAction(position: UIViewAnimatingPosition) {
        titleLabel.alpha = 1
        largeTitleLabel.alpha = 0
        if position == .start {
            titleLabel.alpha = 0
            largeTitleLabel.alpha = 1
        }
        largeTitleImageView.alpha = 1
        transitionLargeTitle.removeFromSuperview()
    }
}

private struct TitleTransitioningLargeToLarge: CNavBarTitleTransitioning {
    

    private let transitionNewLargeTitle: UILabel
    private let largeTitleLabel: UILabel
    
    private let targetX: CGFloat

    init?(navBar: CNavigationBar, newTitle: String?) {
        guard let transitionNewLargeTitle = try? CNavigationHelper.makeCopy(of: navBar.largeTitleLabel) else { return nil }
        
        navBar.addSubview(transitionNewLargeTitle)
        transitionNewLargeTitle.text = newTitle
        transitionNewLargeTitle.frame.size = CNavigationHelper.sizeOf(label: transitionNewLargeTitle,
                                                                      withConstrainedSize: navBar.largeTitleView.bounds.size)
        transitionNewLargeTitle.frame.origin.x = navBar.bounds.width
        transitionNewLargeTitle.frame.origin.y = navBar.largeTitleView.frame.minY + navBar.largeTitleLabel.frame.minY
        transitionNewLargeTitle.alpha = 1
        self.transitionNewLargeTitle = transitionNewLargeTitle
        
        largeTitleLabel = navBar.largeTitleLabel
        largeTitleLabel.alpha = 0
        targetX = navBar.largeTitleLabel.frame.minX
    }
    
    func addAnimations() {
        transitionNewLargeTitle.frame.origin.x = targetX

    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {  }
    
    func completionAction(position: UIViewAnimatingPosition) {
        largeTitleLabel.alpha = 1
        transitionNewLargeTitle.removeFromSuperview()
    }
}

private struct BackButtonTransitioningLargeToLarge: CNavBarTitleTransitioning, CNavItemsTransitioning {
    
    private let transitionLargeTitle: UILabel
    private let transitionLargeToBackButtonTitle: UILabel
    var currentBarItems: [UIView] = []
    var newBarItems: [UIView] = []

    private let targetScale: CGFloat
    private let backButtonOrigin: CGPoint
    private let targetX: CGFloat
    private let transitionLargeToBackButtonAlpha: CGFloat
    
    init?(navBar: CNavigationBar,
          newTitle: String?,
          oldNavComponents: CNavComponents,
          newNavComponents: CNavComponents,
          backTitleVisible: Bool) {
        guard let transitionLargeTitle = try? CNavigationHelper.makeCopy(of: navBar.largeTitleLabel),
              let transitionLargeBlueTitle = try? CNavigationHelper.makeCopy(of: transitionLargeTitle) else { return nil }
        
        navBar.addSubview(transitionLargeTitle)
        navBar.bringSubviewToFront(navBar.navBarBlur)
        navBar.bringSubviewToFront(navBar.divider)
        navBar.bringSubviewToFront(navBar.navBarContentView)
        transitionLargeTitle.frame.origin.x = navBar.largeTitleLabel.frame.minX
        transitionLargeTitle.frame.origin.y = navBar.largeTitleView.frame.minY + navBar.largeTitleLabel.frame.minY
        self.transitionLargeTitle = transitionLargeTitle
        
        navBar.addSubview(transitionLargeBlueTitle)
        transitionLargeBlueTitle.frame = transitionLargeTitle.frame
        transitionLargeBlueTitle.textColor = navBar.backButton.label.textColor
        transitionLargeBlueTitle.font = .systemFont(ofSize: transitionLargeBlueTitle.font.pointSize, weight: .regular)
        transitionLargeBlueTitle.alpha = 0
        self.transitionLargeToBackButtonTitle = transitionLargeBlueTitle
        transitionLargeToBackButtonAlpha = backTitleVisible ? 1 : 0
        
        targetScale = navBar.backButton.label.frame.height / transitionLargeTitle.frame.height
        let backButtonOrigin = CGPoint(x: navBar.backButton.label.frame.minX,
                                       y: navBar.backButton.label.frame.minY + navBar.navBarContentView.frame.minY)
        self.backButtonOrigin = CGPoint(x: backButtonOrigin.x - (transitionLargeTitle.frame.width * (1 - targetScale)) / 2,
                                        y: backButtonOrigin.y - (transitionLargeTitle.frame.height * (1 - targetScale)) / 2)
        navBar.largeTitleLabel.alpha = 0
        targetX = navBar.largeTitleLabel.frame.minX
        navBar.set(title: newTitle)
        
        setupWith(navBarContentView: navBar.navBarContentView, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)
    }
    
    func addAnimations() {
        if transitionLargeToBackButtonAlpha == 1 {
            transitionLargeTitle.frame.origin = backButtonOrigin
            transitionLargeTitle.transform = .init(scaleX: targetScale, y: targetScale)
        
            transitionLargeToBackButtonTitle.frame.origin = backButtonOrigin
            transitionLargeToBackButtonTitle.transform = .init(scaleX: targetScale, y: targetScale)
        }
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        animateNavItems(in: animator, duration: duration)
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: transitionLargeToBackButtonAlpha == 1 ? 0.8 : 0.6) {
                    transitionLargeTitle.alpha = 0
                }
            })
        }
        animator.addAnimations({
            transitionLargeToBackButtonTitle.alpha = transitionLargeToBackButtonAlpha
        }, delayFactor: 0.6)
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        transitionLargeTitle.removeFromSuperview()
        transitionLargeToBackButtonTitle.removeFromSuperview()
        navItemsCompletionAction()
    }
}

private struct BackButtonTransitioningSmallToSmall: CNavBarTitleTransitioning, CNavItemsTransitioning {
    
    private let transitionBackButtonLabel: UILabel
    var currentBarItems: [UIView] = []
    var newBarItems: [UIView] = []
    
    private let targetX: CGFloat
    
    init?(navBarContent: CNavigationBarContentView,
          backButtonTitle: String?,
          oldNavComponents: CNavComponents,
          newNavComponents: CNavComponents) {
        guard let transitionBackButtonLabel = try? CNavigationHelper.makeCopy(of: navBarContent.backButton.label) else { return nil }
        
        transitionBackButtonLabel.text = backButtonTitle
        navBarContent.addSubview(transitionBackButtonLabel)
        transitionBackButtonLabel.frame.size = CNavigationHelper.sizeOf(label: transitionBackButtonLabel, withConstrainedSize: navBarContent.bounds.size)
        transitionBackButtonLabel.center = navBarContent.titleLabel.center
        transitionBackButtonLabel.alpha = 0
        self.transitionBackButtonLabel = transitionBackButtonLabel
        
        targetX = navBarContent.backButton.label.frame.minX
        
        setupWith(navBarContentView: navBarContent, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)
    }
    
    func addAnimations() {
        transitionBackButtonLabel.frame.origin.x = targetX
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        animateNavItems(in: animator, duration: duration)
        animator.addAnimations({
            transitionBackButtonLabel.alpha = 1
        }, delayFactor: 0.3)
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        transitionBackButtonLabel.removeFromSuperview()
        navItemsCompletionAction()
    }
}
