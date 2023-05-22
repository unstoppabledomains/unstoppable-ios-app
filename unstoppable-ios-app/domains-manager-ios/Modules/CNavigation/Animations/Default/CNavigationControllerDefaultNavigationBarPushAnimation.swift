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
              let nav = fromViewController.cNavigationController
        else { return nil }
        
        let navBar = nav.navigationBar!
        let containerView = transitionContext.containerView
        let fromNavChild = fromViewController.cNavigationControllerChild
        let toNavChild = toViewController.cNavigationControllerChild
        let isBackButtonHidden = navBar.backButton.alpha == 0
        let toYOffset = CNavigationHelper.contentYOffset(in: toViewController.view)
        let duration = transitionDuration(using: transitionContext)
        
        if let cNav = toViewController as? CNavigationController {
            cNav.navigationBar.setBackButton(hidden: true)
        }
        
        /// Back button logic
        navBar.setBackButton(hidden: false)
        let navBackButtonSnapshot = navBar.navBarContentView.backButton.renderedImageView()
        navBackButtonSnapshot.frame = navBar.navBarContentView.backButton.calculateFrameInWindow()
        navBar.setBackButton(hidden: true)
        if isBackButtonHidden {
            navBackButtonSnapshot.alpha = 0
        }
        
        let navItemsTransitionPerformer = NavBarItemsTransitionPerformer()
        navItemsTransitionPerformer.setupWithCurrent(navBarContentView: navBar.navBarContentView)

        let navBarSnapshot = UIImageView(frame: navBar.frame)
        navBarSnapshot.image = navBar.toImageInWindowHierarchy()
        navBarSnapshot.frame = navBar.calculateFrameInWindow()
        navBar.window?.addSubview(navBarSnapshot)
        navBar.window?.addSubview(navBackButtonSnapshot)

        navBar.setupWith(child: toNavChild, navigationItem: toViewController.navigationItem)
        CNavigationBarScrollingController().setYOffset(toYOffset, in: navBar)
        navItemsTransitionPerformer.setupWithNew(navBarContentView: navBar.navBarContentView)
        navItemsTransitionPerformer.addToWindow(navBar.window)
        navBar.frame.origin.x = containerView.bounds.width
        
        let animator = createAnimatorIn(transitionContext: transitionContext) {
            navBar.frame.origin.x = 0
            navBarSnapshot.frame.origin.x = -(containerView.frame.size.width / 2)
        }

        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                    navBarSnapshot.alpha = 0
                }
                
                /// Back button logic
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                    navBackButtonSnapshot.alpha = 1
                }
            })
            
            navItemsTransitionPerformer.performAnimationsWith(duration: duration)
        }
        
        animator.addCompletion { position in
            navBar.frame.origin = .zero
            navBarSnapshot.removeFromSuperview()
            navBackButtonSnapshot.removeFromSuperview()
            
            if position == .start {
                navItemsTransitionPerformer.finishTransition(isFinished: false)
                navBar.setBackButton(hidden: isBackButtonHidden)
                navBar.setupWith(child: fromNavChild, navigationItem: fromViewController.navigationItem)
            } else {
                navItemsTransitionPerformer.finishTransition(isFinished: true)
                navBar.setBackButton(hidden: false)
                if let cNav = toViewController as? CNavigationController {
                    cNav.navigationBar.setBackButton(hidden: false)
                }
            }
        }
        
        return animator
    }
}

final class NavBarItemsTransitionPerformer {
    
    private var fromBarViews = [UIView]()
    private var toBarViews = [UIView]()
    private var fromSnapshots = [UIView]()
    private var toSnapshots = [UIView]()
    private var allSnapshots: [UIView] { fromSnapshots + toSnapshots }
    
    func setupWithCurrent(navBarContentView: CNavigationBarContentView) {
        fromBarViews = getBarViewsFrom(navBarContentView: navBarContentView)
        fromSnapshots = getSnapshotsFrom(views: fromBarViews)
        
        setViews(fromBarViews, hidden: true)
    }
    
    func setupWithNew(navBarContentView: CNavigationBarContentView) {
        toBarViews = getBarViewsFrom(navBarContentView: navBarContentView)
        toSnapshots = getSnapshotsFrom(views: toBarViews)
        
        setViews(toBarViews, hidden: true)
        setViews(toSnapshots, hidden: true)
    }
    
    func addToWindow(_ window: UIWindow?) {
        allSnapshots.forEach { view in
            window?.addSubview(view)
        }
    }
    
    private func getSnapshotsFrom(views: [UIView]) -> [UIView] {
        var snapshots = [UIView]()
        for navComponent in views {
            let navAlpha = navComponent.alpha
            navComponent.alpha = 1
            let snapshot = navComponent.renderedImageView()
            snapshot.frame = navComponent.calculateFrameInWindow()
            snapshots.append(snapshot)
            navComponent.alpha = navAlpha
        }
        return snapshots
    }
    
    private func getBarViewsFrom(navBarContentView: CNavigationBarContentView) -> [UIView] {
        navBarContentView.leftBarViews + navBarContentView.rightBarViews
    }
    
    private func setViews(_ views: [UIView], hidden: Bool) {
        let alpha: CGFloat = hidden ? 0 : 1
        views.forEach { view in
            view.alpha = alpha
        }
    }
    
    func performAnimationsWith(duration: TimeInterval) {
        UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                self.setViews(self.fromSnapshots, hidden: true)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.setViews(self.toSnapshots, hidden: false)
            }
        })
    }
    
    func finishTransition(isFinished: Bool) {
        allSnapshots.forEach { view in
            view.removeFromSuperview()
        }
        
        if isFinished {
            setViews(toBarViews, hidden: false)
        } else {
            setViews(fromBarViews, hidden: false)
        }
    }
    
}
