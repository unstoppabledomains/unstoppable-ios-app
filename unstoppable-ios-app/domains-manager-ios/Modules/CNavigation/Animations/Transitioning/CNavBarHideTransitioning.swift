//
//  CNavBarHideTransitioning.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

struct CNavBarHideTransitioning: CNavBarTitleTransitioning {
    
    private let navBar: CNavigationBar
    private let willHide: Bool
    
    init(navBar: CNavigationBar, willHide: Bool) {
        self.navBar = navBar
        self.willHide = willHide
        if !willHide {
            navBar.alpha = 0
            navBar.isHidden = false
            navBar.navBarContentView.alpha = 0
        }
    }
    
    func addAnimations() { }
    
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        let startTime: CGFloat = willHide ? 0.0 : 0.6
        let relativeDuration: CGFloat = willHide ? 0.6 : 0.5
        let alpha: CGFloat = willHide ? 0 : 1
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: relativeDuration) {
                    navBar.alpha = alpha
                    navBar.navBarContentView.alpha = alpha
                }
            })
        }
    }
    
    func completionAction(position: UIViewAnimatingPosition) {
        navBar.alpha = 1
        if position == .start {
            if !willHide {
                navBar.alpha = 1
                navBar.isHidden = true
            }
        }
    }
}
