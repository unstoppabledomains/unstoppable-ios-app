//
//  PullUpNamespace.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.09.2023.
//

import Foundation

enum PullUpNamespace {
    
    enum AddWalletPullUpPresentationOptions {
        case `default`, claimWithoutWallets
        
        var title: String? {
            switch self {
            case .default:
                return nil
            case .claimWithoutWallets:
                return String.Constants.noWalletsToClaimAlertTitle.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .default:
                return nil
            case .claimWithoutWallets:
                return String.Constants.noWalletsToClaimAlertSubtitle.localized()
            }
        }
    }
    
}
