//
//  DomainProfileBadgeDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.08.2023.
//

import UIKit

struct DomainProfileBadgeDisplayInfo: Hashable {
    
    let badge: BadgesInfo.BadgeInfo
    var isExploreWeb3Badge: Bool = false
    var icon: UIImage? = nil

    var defaultIcon: UIImage {
        isExploreWeb3Badge ? .magicWandIcon : .badgesStarIcon24
    }
    
    func loadBadgeIcon() async -> UIImage? {
        if badge.code == "Web3DomainHolder" {
            // Hard code specifically for UD logo in mobile app. Request from designer.
            return .udBadgeLogo
        } else if let url = URL(string: badge.logo) {
            return await appContext.imageLoadingService.loadImage(from: .url(url, 
                                                                             maxSize: Constants.downloadedIconMaxSize),
                                                                  downsampleDescription: .icon)
        }
        return nil
    }
}
