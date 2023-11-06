//
//  BadgeLeaderboardSelectionItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.03.2023.
//

import UIKit

struct BadgeLeaderboardSelectionItem: PullUpCollectionViewCellItem {
    
    var title: String {
        if let rank = badgeDetailedInfo.usage.rank {
            return String.Constants.profileBadgesLeaderboardRankMessage.localized(largeNumberFormatter.string(from: rank as NSNumber) ?? "")
        } else {
            return "-"
        }
    }
    var icon: UIImage {
        get async {
            .rewardsIcon20
        }
    }
    var subtitle: String? {
        String.Constants.profileBadgesLeaderboardHoldersMessage.localized(largeNumberFormatter.string(from: badgeDetailedInfo.usage.holders as NSNumber) ?? "")
    }
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { .topRight }
    
    var isSelectable: Bool = true
    var analyticsName: String = "leaderboard"
    
    let badgeDetailedInfo: BadgeDetailedInfo
    
}
