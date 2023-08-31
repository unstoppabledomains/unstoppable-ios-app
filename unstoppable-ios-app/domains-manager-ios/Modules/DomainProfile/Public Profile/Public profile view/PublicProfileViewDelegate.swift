//
//  PublicProfileViewDelegate.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.08.2023.
//

import UIKit

protocol PublicProfileViewDelegate: AnyObject {
    func publicProfileDidSelectBadge(_ badge: DomainProfileBadgeDisplayInfo, in profile: DomainName)
    func publicProfileDidSelectShareProfile(_ profile: DomainName)
    func publicProfileDidSelectMessagingProfile(_ profile: DomainName)
    func publicProfileDidSelectOpenLeaderboard()
}

// MARK: - Open methods
extension UIViewController: PublicProfileViewDelegate {
    func publicProfileDidSelectBadge(_ badge: DomainProfileBadgeDisplayInfo, in profile: DomainName) {
        appContext.pullUpViewService.showBadgeInfoPullUp(in: getViewControllerToPresent(),
                                                         badgeDisplayInfo: badge,
                                                         domainName: profile)
    }
    
    func publicProfileDidSelectShareProfile(_ profile: DomainName) {
        getViewControllerToPresent().shareDomainProfile(domainName: profile)
    }
    
    func publicProfileDidSelectMessagingProfile(_ profile: DomainName) {
        
    }
    
    func publicProfileDidSelectOpenLeaderboard() {
        getViewControllerToPresent().openLink(.badgesLeaderboard)
    }
    
    private func getViewControllerToPresent() -> UIViewController {
        topVisibleViewController()
    }
}
