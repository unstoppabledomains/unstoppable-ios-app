//
//  WalletDetailsAddWalletAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import Foundation
import UIKit

enum WalletDetailsAddWalletAction: String, CaseIterable, PullUpCollectionViewCellItem {
    
    case create, recoveryOrKey, connect, mpc
    
    var title: String {
        switch self {
        case .create:
            return String.Constants.createVault.localized()
        case .recoveryOrKey:
            return String.Constants.connectWalletRecovery.localized()
        case .connect:
            return String.Constants.connectWalletExternal.localized()
        case .mpc:
            return "Unstoppable guard"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .create:
            return nil
        case .recoveryOrKey:
            return nil
        case .connect:
            return String.Constants.connectWalletExternalHint.localized()
        case .mpc:
            return "Advanced MPC technoloiges"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .create:
            return .plusIconSmall
        case .recoveryOrKey:
            return .recoveryPhraseIcon
        case .connect:
            return .externalWalletIndicator
        case .mpc:
            return UIImage(systemName: "flame.fill")!
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .create:
            return .foregroundOnEmphasis
        case .recoveryOrKey, .connect:
            return .foregroundDefault
        case .mpc:
            return .brandOrange
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .create:
            return .backgroundAccentEmphasis
        case .recoveryOrKey, .connect, .mpc:
            return .backgroundMuted2
        }
    }
    
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { .right }
    var analyticsName: String { rawValue }
    
}
