//
//  OnboardingAddWalletType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import UIKit

enum OnboardingAddWalletType: OnboardingStartOption {
    case mpcWallet, selfCustody
    
    var type: OnboardingStartOptionType {
        switch self {
        case .mpcWallet:
            return .generic(OnboardingBuyMPCOptionViewBuilder())
        case .selfCustody:
            return .listItem(.init(icon: icon,
                                   title: title,
                                   subtitle: subtitle,
                                   subtitleType: subtitleType,
                                   imageStyle: imageStyle))
        }
    }
    
    var icon: UIImage {
        switch self {
        case .mpcWallet:
            return .shieldKeyhole
        case .selfCustody:
            return .walletExternalIcon
        }
    }
    
    var title: String {
        switch self {
        case .mpcWallet:
            return String.Constants.mpcProductName.localized()
        case .selfCustody:
            return String.Constants.selfCustody.localized()
        }
    }
    
    var subtitle: String? {
        switch self {
        case .mpcWallet:
            return nil
        case .selfCustody:
            return String.Constants.createWalletOnboardingSubtitle.localized()
        }
    }
    
    var subtitleType: UDListItemView.SubtitleStyle {
        .default
    }
    
    var imageStyle: UDListItemView.ImageStyle {
        switch self {
        case .mpcWallet:
            return .centred(background: .backgroundAccentEmphasis)
        case .selfCustody:
            return .centred()
        }
    }
    
    var analyticsName: Analytics.Button {
        switch self {
        case .mpcWallet:
            return .mpc
        case .selfCustody:
            return .selfCustody
        }
    }
}
