//
//  WalletDetailsAddWalletAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import Foundation
import UIKit

enum WalletDetailsAddWalletAction: String, CaseIterable, PullUpCollectionViewCellItem {
    
    case mpc, recoveryOrKey, connect, create
    
    var title: String {
        switch self {
        case .create:
            return String.Constants.createNewVaultTitle.localized()
        case .recoveryOrKey:
            return String.Constants.connectWalletRecovery.localized()
        case .connect:
            return String.Constants.connectWalletExternal.localized()
        case .mpc:
            return String.Constants.importMPCWalletTitle.localizedMPCProduct()
        }
    }
    
    var subtitle: String? {
        switch self {
        case .create:
            return nil
        case .recoveryOrKey:
            return nil
        case .connect:
            return nil
        case .mpc:
            return nil
        }
    }
    
    var icon: UIImage {
        switch self {
        case .create:
            return .plusIconSmall
        case .recoveryOrKey:
            return .pageText
        case .connect:
            return .externalWalletIndicator
        case .mpc:
            return .shieldKeyhole
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .recoveryOrKey, .connect, .create, .mpc:
            return .foregroundDefault
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .recoveryOrKey, .connect, .mpc, .create:
            return .backgroundMuted2
        }
    }
    
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { .right }
    var analyticsName: String { rawValue }
    
}
