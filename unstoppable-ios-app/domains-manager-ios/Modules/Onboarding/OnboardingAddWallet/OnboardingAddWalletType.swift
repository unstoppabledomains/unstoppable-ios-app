//
//  OnboardingAddWalletType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import UIKit

enum OnboardingAddWalletType: OnboardingStartOption {
    case mpcWallet, selfCustody
    
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
            return "Full cryptocurrency wallet for Web3 with enhanced backup."
        case .selfCustody:
            return "Weak security and backup."
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
