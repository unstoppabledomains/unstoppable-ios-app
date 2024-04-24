//
//  PullUpNamespace.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.09.2023.
//

import Foundation

enum PullUpNamespace {
    
    enum AddWalletPullUpPresentationOptions {
        case `default`, claimWithoutWallets, addToPurchase
        
        var title: String? {
            switch self {
            case .default:
                return String.Constants.connectWalletTitle.localized()
            case .claimWithoutWallets:
                return String.Constants.noWalletsToClaimAlertTitle.localized()
            case .addToPurchase:
                return String.Constants.noWalletsToPurchaseAlertTitle.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .default:
                return nil
            case .claimWithoutWallets:
                return String.Constants.noWalletsToClaimAlertSubtitle.localized()
            case .addToPurchase:
                return String.Constants.noWalletsToPurchaseAlertSubtitle.localized()
            }
        }
    }
    
}
