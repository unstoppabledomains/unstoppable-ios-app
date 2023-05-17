//
//  ViewWithDashesProgress.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol ViewWithDashesProgress: UIViewController & CNavigationControllerChildTransitioning {
    var progress: Double? { get }
    var dashesProgressView: DashesProgressView! { get }
    func setDashesProgress(_ progress: Double?)
}

extension ViewWithDashesProgress {
    var dashesProgressView: DashesProgressView! {
        get { navigationItem.titleView as? DashesProgressView }
    }

    
    func setDashesProgress(_ progress: Double?) {
        if let progress = progress {
            dashesProgressView.setProgress(progress)
        }
        dashesProgressView.alpha = progress == nil ? 0 : 1
        cNavigationBar?.navBarContentView.setTitleView(hidden: progress == nil, animated: false)
    }

    func addProgressDashesView() {
        if let dashesProgressView = cNavigationController?.navigationBar.navBarContentView.titleView as? DashesProgressView {
            navigationItem.titleView = dashesProgressView
        } else {
            let dashesProgressView = DashesProgressView(frame: CGRect(x: 0, y: 0, width: 160, height: 4))
            navigationItem.titleView = dashesProgressView
            dashesProgressView.setProgress(0.0)            
        }
    }
    
    func pushNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let viewWithDashesProgress = viewController as? ViewWithDashesProgress {
            
            return DashesProgressNavBarPushAnimation(animationDuration: CNavigationHelper.DefaultNavAnimationDuration,
                                                     toProgress: viewWithDashesProgress.progress)
        }
        return nil
    }

    func popNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let viewWithDashesProgress = viewController as? ViewWithDashesProgress,
           let progress = viewWithDashesProgress.progress {
            
            return DashesProgressNavBarPopAnimation(animationDuration: CNavigationHelper.DefaultNavAnimationDuration, toProgress: progress)
        }
        return nil
    }
}
