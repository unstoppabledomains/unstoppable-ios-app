//
//  CNavItemsTransitioning.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

protocol CNavItemsTransitioning {
    var currentBarItems: [UIView] { get set }
    var newBarItems: [UIView] { get set }
    
    mutating func setupWith(navBarContentView: CNavigationBarContentView, oldNavComponents: CNavComponents, newNavComponents: CNavComponents)
    func animateNavItems(in animator: UIViewPropertyAnimator, duration: TimeInterval)
    func navItemsCompletionAction()
}

extension CNavItemsTransitioning {
    mutating func setupWith(navBarContentView: CNavigationBarContentView, oldNavComponents: CNavComponents, newNavComponents: CNavComponents) {
        if let newTitleView = newNavComponents.titleView {
            let alpha = newTitleView.alpha
            newTitleView.alpha = 1
            let image = CNavigationHelper.viewToImage(newTitleView)
            newTitleView.alpha = alpha
            
            let imageView = UIImageView(image: image)
            imageView.frame = newTitleView.bounds
            
            navBarContentView.addSubview(imageView)
            imageView.center = navBarContentView.titleLabel.center
            imageView.alpha = 0
            newBarItems = [imageView]
        }
        
        if let navBarCopy = try? CNavigationHelper.makeCopy(of: navBarContentView) {
            navBarCopy.setBarButtons(newNavComponents.leftItems, rightItems: newNavComponents.rightViews)
            let newBarItems = navBarCopy.leftBarViews + navBarCopy.rightBarViews
            newBarItems.forEach { view in
                navBarContentView.addSubview(view)
                view.alpha = 0
            }
            self.newBarItems += newBarItems
        }
        
        currentBarItems = oldNavComponents.allViews + navBarContentView.leftBarViews + navBarContentView.rightBarViews
    }
    
    func animateNavItems(in animator: UIViewPropertyAnimator, duration: TimeInterval) {
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.7) {
                    currentBarItems.forEach { item in
                        item.alpha = 0
                    }
                }
            })
        }
        animator.addAnimations({
            newBarItems.forEach { item in
                item.alpha = 1
            }
        }, delayFactor: 0.4)
    }
    
    func navItemsCompletionAction() {
        newBarItems.forEach { view in
            view.removeFromSuperview()
        }
    }
}
