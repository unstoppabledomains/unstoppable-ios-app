//
//  RestoreWalletType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import UIKit

enum RestoreWalletType: Hashable, OnboardingStartOption {
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
            return .vaultSafeIcon
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
            return String.Constants.importMPCWalletTitle.localized()
        }
    }
    
    var subtitle: String? {
        switch self {
        case .iCloud:
            return String.Constants.connectWalletICloudHint.localized()
        case .recoveryPhrase:
            return nil
        case .watchWallet:
            return nil
        case .externalWallet:
            return nil
        case .websiteAccount:
            return nil
        case .mpc:
            return nil
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
