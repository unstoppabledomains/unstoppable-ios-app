//
//  NavBarItemsTransitionPerformer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.05.2023.
//

import UIKit

@MainActor
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
