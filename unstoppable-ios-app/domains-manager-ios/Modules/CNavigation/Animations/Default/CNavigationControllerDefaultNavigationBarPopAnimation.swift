//
//  NavigationControllerDefaultNavigationBarPopAnimation.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

final class CNavigationControllerDefaultNavigationBarPopAnimation: CBaseTransitioningAnimation {
    
    override func buildAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let navBar = fromViewController.cNavigationController?.navigationBar,
              let navBarContent = navBar.navBarContentView,
              let transitionFromTitle = try? CNavigationHelper.makeCopy(of: navBarContent.titleLabel) else { return nil }
        let isLastViewController = toViewController == fromViewController.cNavigationController?.rootViewController

        let newTitle = toViewController.title ?? navBarContent.defaultBackButtonTitle
        var newBackButtonTitle: String?
        
        if !isLastViewController,
           let nav = fromViewController.cNavigationController,
           let i = nav.viewControllers.firstIndex(of: toViewController),
           i > 0 {
            newBackButtonTitle = nav.viewControllers[i-1].title
        }
        
        let toNavChild = toViewController as? CNavigationControllerChild
        let fromNavChild = fromViewController as? CNavigationControllerChild
        
        // Type of transition
        let toPreferLarge = toNavChild?.prefersLargeTitles ?? false
        let fromPreferLarge = fromNavChild?.prefersLargeTitles ?? false
        let fromYOffset = CNavigationHelper.contentYOffset(in: fromViewController.view)
        let isLargeTitleCollapsed = CNavigationBarScrollingController().isLargeTitleHidden(navBar.largeTitleLabel,
                                                                                           in: navBar,
                                                                                           yOffset: fromYOffset)
        let oldNavComponents = CNavComponents(viewController: fromViewController)
        let newNavComponents = CNavComponents(viewController: toViewController)
        let yOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        let contentOffset = (toViewController as? CNavigationControllerChild)?.scrollableContentYOffset ?? 0
        let isBlurActive = yOffset > contentOffset

        let titleTransitioning: CNavBarTitleTransitioning
        let backButtonTransitioning: CNavBarTitleTransitioning
        switch (fromPreferLarge, toPreferLarge) {
        case (false, false):
            backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, newBackButtonTitle: newBackButtonTitle, isLastViewController: isLastViewController, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
            titleTransitioning = TitleTransitioningSmallToSmall(navBarContent: navBarContent, newTitle: toViewController.title, newNavComponents: newNavComponents)!
            navBarContent.titleLabel.textColor = toNavChild?.navBarTitleAttributes?[.foregroundColor] as? UIColor
        case (false, true):
            backButtonTransitioning = BackButtonTransitioningLargeToLarge(navBar: navBar, newBackButtonTitle: newBackButtonTitle, isLastViewController: isLastViewController, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
            titleTransitioning = TitleTransitioningSmallToLarge(navBar: navBar)!
        case (true, false):
            if isLargeTitleCollapsed {
                backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, newBackButtonTitle: newBackButtonTitle, isLastViewController: isLastViewController, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
                titleTransitioning = TitleTransitioningSmallToSmall(navBarContent: navBarContent, newTitle: toViewController.title, newNavComponents: newNavComponents)!
            } else {
                backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, newBackButtonTitle: newBackButtonTitle, isLastViewController: isLastViewController, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
                titleTransitioning = TitleTransitioningLargeToSmall(navBar: navBar, newTitle: toViewController.title, newNavComponents: newNavComponents)!
            }
           
        case (true, true):
            if isLargeTitleCollapsed {
                backButtonTransitioning = BackButtonTransitioningSmallToSmall(navBarContent: navBarContent, newBackButtonTitle: newBackButtonTitle, isLastViewController: isLastViewController, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
                titleTransitioning = TitleTransitioningSmallToSmall(navBarContent: navBarContent, newTitle: toViewController.title, newNavComponents: newNavComponents)!
            } else {
                backButtonTransitioning = BackButtonTransitioningLargeToLarge(navBar: navBar, newBackButtonTitle: newBackButtonTitle, isLastViewController: isLastViewController, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
                titleTransitioning = TitleTransitioningLargeToLarge(navBar: navBar, newTitle: toViewController.title)!
            }
        }
        
        // isHidden
        let toIsHidden = toNavChild?.isNavBarHidden ?? false || toViewController is CNavigationController
        let fromIsHidden = fromNavChild?.isNavBarHidden ?? false || fromViewController is CNavigationController
        var navBarVisibilityTransitioning: CNavBarTitleTransitioning?
        
        if toIsHidden != fromIsHidden {
            navBarVisibilityTransitioning = CNavBarHideTransitioning(navBar: navBar, willHide: toIsHidden)
        }
        var backButtonTransitionImage: UIImageView?
        let isBackButtonHidden = isLastViewController && !navBar.alwaysShowBackButton
        if navBarContent.backButton.icon.image != toNavChild?.navBackButtonConfiguration.backArrowIcon,
           !isBackButtonHidden {
            backButtonTransitionImage = try? CNavigationHelper.makeCopy(of: navBarContent.backButton.icon)
            backButtonTransitionImage?.image = navBarContent.backButton.icon.image
            if let backButtonTransitionImage = backButtonTransitionImage {
                navBarContent.backButton.icon.alpha = 0
                navBarContent.backButton.addSubview(backButtonTransitionImage)
            }
        }
        
        
        let duration = transitionDuration(using: transitionContext)
        let animator = UIViewPropertyAnimator(duration: duration,
                                              controlPoint1: CNavigationHelper.AnimationCurveControlPoint1,
                                              controlPoint2: CNavigationHelper.AnimationCurveControlPoint2) {
            navBarContent.setBackButton(hidden: isBackButtonHidden)
            navBarContent.backButtonConfiguration = toNavChild?.navBackButtonConfiguration ?? .default
            titleTransitioning.addAnimations()
            backButtonTransitioning.addAnimations()
            navBarVisibilityTransitioning?.addAnimations()
            navBar.navBarBlur.alpha = isBlurActive ? 1 : 0
            navBar.divider.alpha = isBlurActive ? 1 : 0
        }
        
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    backButtonTransitionImage?.alpha = 0
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    navBarContent.backButton.icon.alpha = 1
                }
            })
        }
        
        titleTransitioning.addAdditionalAnimation(in: animator, duration: duration)
        backButtonTransitioning.addAdditionalAnimation(in: animator, duration: duration)
        navBarVisibilityTransitioning?.addAdditionalAnimation(in: animator, duration: duration)

        
        animator.addCompletion { position in
            transitionFromTitle.removeFromSuperview()
            backButtonTransitionImage?.removeFromSuperview()
            navBarContent.backButton.icon.alpha = 1

            titleTransitioning.completionAction(position: position)
            backButtonTransitioning.completionAction(position: position)
            navBarVisibilityTransitioning?.completionAction(position: position)
            if position == .start {
                navBarContent.backButtonConfiguration = fromNavChild?.navBackButtonConfiguration ?? .default
                navBarContent.set(title: fromViewController.title)
                navBarContent.setBackButton(title: newTitle)
            } else {
                navBarContent.set(title: toViewController.title)
                navBarContent.setBackButton(title: newBackButtonTitle ?? "")
            }
        }
        
        return animator
    }
    
}

private struct TitleTransitioningSmallToSmall: CNavBarTitleTransitioning {
    
    private let transitionFromTitle: UILabel
    private let backButtonLabel: UILabel
    private let titleLabel: UILabel
    private let targetX: CGFloat
    private let titleCenter: CGPoint
    private let hasTitleView: Bool

    init?(navBarContent: CNavigationBarContentView,
          newTitle: String?,
          newNavComponents: CNavComponents) {
        guard let transitionFromTitle = try? CNavigationHelper.makeCopy(of: navBarContent.titleLabel) else { return nil }
        
        self.hasTitleView = newNavComponents.titleView != nil
        titleCenter = CNavigationHelper.center(of: navBarContent.bounds)
        navBarContent.addSubview(transitionFromTitle)
        self.transitionFromTitle = transitionFromTitle
        self.backButtonLabel = navBarContent.backButton.label
        
        navBarContent.set(title: newTitle)
        titleLabel = navBarContent.titleLabel!

        titleLabel.alpha = 0
        titleLabel.frame.origin.x = navBarContent.backButton.label.frame.minX
        targetX = navBarContent.frame.width
    }
    
    func addAnimations() {
        backButtonLabel.alpha = 0
        backButtonLabel.center = titleCenter
        transitionFromTitle.frame.origin.x = targetX
        transitionFromTitle.alpha = 0
        titleLabel.center = titleCenter
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                    if !hasTitleView {
                        titleLabel.alpha = 1
                    }
                }
            })
        }
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        if !hasTitleView {
            titleLabel.alpha = 1
        }
        backButtonLabel.alpha = 1
        backButtonLabel.mask =  nil
        transitionFromTitle.removeFromSuperview()
    }
}

private struct TitleTransitioningSmallToLarge: CNavBarTitleTransitioning {
    
    private let transitionFromTitle: UILabel
    private let backButtonLabel: UILabel
    private let titleLabel: UILabel
    private let targetX: CGFloat
    private let titleCenter: CGPoint
    
    init?(navBar: CNavigationBar) {
        let navBarContent = navBar.navBarContentView!
        guard let transitionFromTitle = try? CNavigationHelper.makeCopy(of: navBarContent.titleLabel) else { return nil }
        
        titleCenter = CNavigationHelper.center(of: navBarContent.bounds)
        navBarContent.addSubview(transitionFromTitle)
        self.transitionFromTitle = transitionFromTitle
        self.backButtonLabel = navBarContent.backButton.label
        titleLabel = navBarContent.titleLabel
        titleLabel.alpha = 0
        targetX = navBarContent.frame.width
        backButtonLabel.alpha = 0
    }
    
    func addAnimations() {
        transitionFromTitle.frame.origin.x = targetX
        transitionFromTitle.alpha = 0
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
       
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        if position == .start {
            titleLabel.alpha = 1
        }
        backButtonLabel.alpha = 1
        transitionFromTitle.removeFromSuperview()
    }
}


private struct TitleTransitioningLargeToSmall: CNavBarTitleTransitioning {
    
    private let backButtonLabel: UILabel
    private let titleLabel: UILabel
    private let largeTitleLabel: UILabel
    private let largeTitleImageView: UIImageView

    private let originalX: CGFloat
    private let originalImageX: CGFloat
    private let targetX: CGFloat
    private let imageTargetX: CGFloat
    private let titleCenter: CGPoint
    private let hasTitleView: Bool
     
    init?(navBar: CNavigationBar,
          newTitle: String?,
          newNavComponents: CNavComponents) {
        let navBarContent = navBar.navBarContentView!
        
        self.hasTitleView = newNavComponents.titleView != nil
        titleCenter = CNavigationHelper.center(of: navBarContent.bounds)
        backButtonLabel = navBarContent.backButton.label
        
        navBarContent.set(title: newTitle)
        titleLabel = navBarContent.titleLabel!
        largeTitleLabel = navBar.largeTitleLabel
        largeTitleImageView = navBar.largeTitleImageView
        originalX = largeTitleLabel.frame.origin.x
        originalImageX = largeTitleImageView.frame.origin.x
        
        titleLabel.alpha = 0
        titleLabel.frame.origin.x = navBarContent.backButton.label.frame.minX
        targetX = originalX + navBarContent.frame.width
        imageTargetX = originalImageX + navBarContent.frame.width
    }
    
    func addAnimations() {
        backButtonLabel.alpha = 0
        backButtonLabel.center = titleCenter
        largeTitleLabel.frame.origin.x = targetX
        largeTitleImageView.frame.origin.x = imageTargetX
        titleLabel.center = titleCenter
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                    if !hasTitleView {
                        titleLabel.alpha = 1
                    }
                }
            })
        }
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        if position == .start {
            titleLabel.alpha = 0
            largeTitleLabel.alpha = 1
        } else {
            if !hasTitleView {
                titleLabel.alpha = 1
            }
            largeTitleLabel.alpha = 0
        }
        
        largeTitleLabel.frame.origin.x = originalX
        largeTitleImageView.frame.origin.x = originalImageX
        backButtonLabel.alpha = 1
        backButtonLabel.mask =  nil
    }
}

private struct TitleTransitioningLargeToLarge: CNavBarTitleTransitioning {
    

    private let largeTitleLabel: UILabel
    private let backButtonLabel: UILabel

    private let originalX: CGFloat
    private let targetX: CGFloat
    
    init?(navBar: CNavigationBar, newTitle: String?) {
        largeTitleLabel = navBar.largeTitleLabel
        originalX = largeTitleLabel.frame.origin.x
        targetX = navBar.navBarContentView!.frame.width
        self.backButtonLabel = navBar.navBarContentView.backButton.label
        backButtonLabel.alpha = 0
    }
    
    func addAnimations() {
        largeTitleLabel.frame.origin.x = targetX
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        backButtonLabel.alpha = 1
        largeTitleLabel.frame.origin.x = originalX
    }
}

private struct BackButtonTransitioningSmallToSmall: CNavBarTitleTransitioning, CNavItemsTransitioning {
    
    private let transitionBackButtonLabel: UILabel
    
    private let targetX: CGFloat
    private let isLastViewController: Bool
    var currentBarItems: [UIView] = []
    var newBarItems: [UIView] = []
    
    init?(navBarContent: CNavigationBarContentView,
          newBackButtonTitle: String?,
          isLastViewController: Bool,
          oldNavComponents: CNavComponents,
          newNavComponents: CNavComponents) {
        guard let transitionBackButtonLabel = try? CNavigationHelper.makeCopy(of: navBarContent.backButton.label) else { return nil }

        let backButtonFrame = navBarContent.backButton.label.frame

        transitionBackButtonLabel.text = newBackButtonTitle
        transitionBackButtonLabel.frame.size = CNavigationHelper.sizeOf(label: transitionBackButtonLabel, withConstrainedSize: navBarContent.bounds.size)
        navBarContent.addSubview(transitionBackButtonLabel)
        transitionBackButtonLabel.frame.origin.x = -backButtonFrame.width
        transitionBackButtonLabel.alpha = 0
        self.transitionBackButtonLabel = transitionBackButtonLabel
        self.isLastViewController = isLastViewController
        targetX = navBarContent.backButton.label.frame.minX
        
        setupWith(navBarContentView: navBarContent, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents, isLastViewController: isLastViewController)
    }
    
    func addAnimations() {
        transitionBackButtonLabel.frame.origin.x = targetX
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        // Fix with mask
        animator.addAnimations({
            transitionBackButtonLabel.alpha = isLastViewController ? 0 : 1
        }, delayFactor: 0.3)
        animateNavItems(in: animator, duration: duration)
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        transitionBackButtonLabel.removeFromSuperview()
        navItemsCompletionAction()
    }
}

private struct BackButtonTransitioningLargeToLarge: CNavBarTitleTransitioning {
    
    private let transitionBackButtonLabel: UILabel
    private let transitionLargeTitle: UILabel
    private let largeTitleLabel: UILabel
    private let smallTransition: BackButtonTransitioningSmallToSmall
    
    private let largeTitleOriginalAlpha: CGFloat
    private let targetScale: CGFloat
    private let targetPosition: CGPoint
    private let isLastViewController: Bool
    
    init?(navBar: CNavigationBar,
          newBackButtonTitle: String?,
          isLastViewController: Bool,
          oldNavComponents: CNavComponents,
          newNavComponents: CNavComponents) {
        let backButtonLabel = navBar.backButton.label!
        guard let transitionBackButtonLabel = try? CNavigationHelper.makeCopy(of: backButtonLabel),
              let transitionLargeTitle = try? CNavigationHelper.makeCopy(of: transitionBackButtonLabel) else { return nil }
                
        largeTitleLabel = navBar.largeTitleLabel!
        largeTitleOriginalAlpha = largeTitleLabel.alpha

        navBar.addSubview(transitionBackButtonLabel)
        transitionBackButtonLabel.frame.origin = CGPoint(x: backButtonLabel.frame.minX,
                                                         y: navBar.navBarContentView.frame.minY + backButtonLabel.frame.minY)
        
        navBar.addSubview(transitionLargeTitle)
        transitionLargeTitle.frame = transitionBackButtonLabel.frame
        transitionLargeTitle.textColor = navBar.largeTitleLabel.textColor
        transitionLargeTitle.font = .systemFont(ofSize: transitionLargeTitle.font.pointSize, weight: .bold)
        transitionLargeTitle.alpha = 0
        transitionLargeTitle.frame.size = CNavigationHelper.sizeOf(label: transitionLargeTitle, withConstrainedSize: navBar.largeTitleView.bounds.size)
        self.transitionLargeTitle = transitionLargeTitle
        
        targetScale = largeTitleLabel.frame.height / navBar.backButton.label.frame.height

        self.transitionBackButtonLabel = transitionBackButtonLabel
        self.isLastViewController = isLastViewController
        let largeTitleOrigin = navBar.largeTitleLabel.frame.origin
        let targetPosition = CGPoint(x: largeTitleOrigin.x,
                                     y: largeTitleOrigin.y + navBar.largeTitleView.frame.minY)
        self.targetPosition = CGPoint(x: targetPosition.x + ((transitionLargeTitle.frame.width * targetScale) - transitionLargeTitle.frame.width) / 2,
                                      y: targetPosition.y + ((transitionLargeTitle.frame.height * targetScale) - transitionLargeTitle.frame.height) / 2)
        smallTransition = BackButtonTransitioningSmallToSmall(navBarContent: navBar.navBarContentView, newBackButtonTitle: newBackButtonTitle, isLastViewController: isLastViewController, oldNavComponents: oldNavComponents, newNavComponents: newNavComponents)!
    }
    
    func addAnimations() {
        smallTransition.addAnimations()
        transitionBackButtonLabel.frame.origin = targetPosition
        transitionBackButtonLabel.transform = .init(scaleX: targetScale, y: targetScale)

        transitionLargeTitle.frame.origin = targetPosition
        transitionLargeTitle.transform = .init(scaleX: targetScale, y: targetScale)
    }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        smallTransition.addAdditionalAnimation(in: animator, duration: duration)
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.45) {
                    transitionBackButtonLabel.alpha = 0
                }
            })
        }
        animator.addAnimations({
            transitionLargeTitle.alpha = 1
        }, delayFactor: 0.2)
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        smallTransition.completionAction(position: position)
        largeTitleLabel.alpha = 1
        if position == .start {
            largeTitleLabel.alpha = largeTitleOriginalAlpha
        }
        transitionBackButtonLabel.removeFromSuperview()
        transitionLargeTitle.removeFromSuperview()
    }
}
