//
//  RestoreWalletType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import UIKit

enum RestoreWalletType: Hashable {
    case iCloud(value: String), recoveryPhrase, watchWallet, externalWallet, websiteAccount, mpc
    
    var icon: UIImage {
        switch self {
        case .iCloud:
            return .backupICloud
        case .recoveryPhrase:
            return .pageText
        case .watchWallet:
            return #imageLiteral(resourceName: "watchWalletIcon")
        case .externalWallet:
            return #imageLiteral(resourceName: "externalWalletIcon")
        case .websiteAccount:
            return .domainsProfileIcon
        case .mpc:
            return .shieldKeyhole
        }
    }
    
    var title: String {
        switch self {
        case .iCloud:
            return String.Constants.connectWalletICloud.localized()
        case .recoveryPhrase:
            return String.Constants.connectWalletRecovery.localized()
        case .watchWallet:
            return String.Constants.connectWalletWatch.localized()
        case .externalWallet:
            return String.Constants.connectWalletExternal.localized()
        case .websiteAccount:
            return String.Constants.viewVaultedDomains.localized()
        case .mpc:
            return "Unstoppable guard"
            
        }
    }
    
    var subtitle: String? {
        switch self {
        case .iCloud(let value):
            return String.Constants.connectWalletICloudHint.localized()
        case .recoveryPhrase:
            return String.Constants.domainsCollectionEmptyStateImportSubtitle.localized()
        case .watchWallet:
            return String.Constants.connectWalletWatchHint.localized()
        case .externalWallet:
            return String.Constants.connectWalletExternalHint.localized()
        case .websiteAccount:
            return String.Constants.protectedByUD.localized()
        case .mpc:
            return "Advanced MPC technoloiges"
            
        }
    }
    
    var subtitleType: UDListItemView.SubtitleStyle {
        switch self {
        case .iCloud:
            return .accent
        default:
            return .default
        }
    }
    
    var subtitleStyle: TableViewSelectionCell.SecondaryTextStyle {
        switch self {
        case .iCloud:
            return .blue
        case .recoveryPhrase, .watchWallet, .externalWallet, .websiteAccount, .mpc:
            return .grey
        }
    }
    
    var iconStyle: TableViewSelectionCell.IconStyle {
        switch self {
        case .iCloud:
            return .accent
        case .recoveryPhrase, .watchWallet, .externalWallet, .websiteAccount, .mpc:
            return .grey
        }
    }
    var imageStyle: UDListItemView.ImageStyle {
        switch self {
        case .iCloud:
            return .centred(background: .backgroundAccentEmphasis)
        case .recoveryPhrase, .watchWallet, .externalWallet, .websiteAccount, .mpc:
            return .centred()
        }
        
    }
    
    var analyticsName: Analytics.Button {
        switch self {
        case .iCloud:
            return .iCloud
        case .recoveryPhrase:
            return .importWithPKOrSP
        case .watchWallet:
            return .watchWallet
        case .externalWallet:
            return .externalWallet
        case .websiteAccount:
            return .websiteAccount
        case .mpc:
            return .mpc
        }
    }
}
