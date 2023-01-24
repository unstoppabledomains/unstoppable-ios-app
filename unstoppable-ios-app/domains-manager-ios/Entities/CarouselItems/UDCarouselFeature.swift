//
//  UDCarouselFeature.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.10.2022.
//

import UIKit

struct UDCarouselFeature: CarouselViewItem {
    let icon: UIImage
    let text: String
    var tintColor: UIColor { .foregroundSecondary }
    var backgroundColor: UIColor { .backgroundSubtle }

    static let ProfileInfoFeatures: [UDCarouselFeature] = [.init(icon: .rocketIcon20,
                                                                 text: String.Constants.profileInfoCarouselItemPortableIdentity.localized()),
                                                           .init(icon: .badgeIcon20,
                                                                 text: String.Constants.profileInfoCarouselItemBadges.localized()),
                                                           .init(icon: .rewardsIcon20,
                                                                 text: String.Constants.profileInfoCarouselItemRewards.localized()),
                                                           .init(icon: .avatarsIcon20,
                                                                 text: String.Constants.profileInfoCarouselItemAvatars.localized()),
                                                           .init(icon: .checkBadge,
                                                                 text: String.Constants.profileInfoCarouselItemVerifySocials.localized()),
                                                           .init(icon: .planetIcon20,
                                                                 text: String.Constants.profileInfoCarouselItemPublicProfile.localized()),
                                                           .init(icon: .chainIcon,
                                                                 text: String.Constants.profileInfoCarouselItemDataSharing.localized()),
                                                           .init(icon: .walletBTCIcon20,
                                                                 text: String.Constants.profileInfoCarouselItemRoutePayments.localized()),
                                                           .init(icon: .reputationIcon20,
                                                                 text: String.Constants.profileInfoCarouselItemReputation.localized()),
                                                           .init(icon: .vaultIcon,
                                                                 text: String.Constants.profileInfoCarouselItemPermissioning.localized())]
}
