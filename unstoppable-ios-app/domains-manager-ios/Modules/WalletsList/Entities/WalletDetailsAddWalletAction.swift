//
//  WalletDetailsAddWalletAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import Foundation
import UIKit

enum WalletDetailsAddWalletAction: String, CaseIterable, PullUpCollectionViewCellItem {
    
    case create, recoveryOrKey, connect
    
    var title: String {
        switch self {
        case .create:
            return String.Constants.createVault.localized()
        case .recoveryOrKey:
            return String.Constants.connectWalletRecovery.localized()
        case .connect:
            return String.Constants.connectWalletExternal.localized()
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
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .create:
            return .foregroundOnEmphasis
        case .recoveryOrKey, .connect:
            return .foregroundDefault
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .create:
            return .backgroundAccentEmphasis
        case .recoveryOrKey, .connect:
            return .backgroundMuted2
        }
    }
    
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { .right }
    var analyticsName: String { rawValue }
    
}
