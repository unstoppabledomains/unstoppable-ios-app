//
//  AddDomainPullUpAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import UIKit

enum AddDomainPullUpAction: String, CaseIterable, PullUpCollectionViewCellItem {
    case connectWallet, importFromWebsite, importWallet
    case findNew
    
    static let pullUpSections: [[AddDomainPullUpAction]] = [[.importWallet, .connectWallet, .importFromWebsite], [.findNew]]
    
    var title: String {
        switch self {
        case .importFromWebsite:
            return String.Constants.claimDomainsToSelfCustodial.localized()
        case .importWallet:
            return String.Constants.connectWalletRecovery.localized()
        case .connectWallet:
            return String.Constants.connectWalletExternal.localized()
        case .findNew:
            return String.Constants.findANewDomain.localized()
        }
    }
    
    var subtitle: String? {
        switch self {
        case .importFromWebsite:
            return nil
        case .importWallet:
            return String.Constants.domainsCollectionEmptyStateImportSubtitle.localized()
        case .connectWallet:
            return String.Constants.domainsCollectionEmptyStateExternalSubtitle.localized()
        case .findNew:
            return nil
        }
    }
    
    var icon: UIImage {
        switch self {
        case .importFromWebsite:
            return .sparklesIcon
        case .importWallet:
            return .recoveryPhraseIcon
        case .connectWallet:
            return .externalWalletIndicator
        case .findNew:
            return .searchIcon
        }
    }
    var tintColor: UIColor {
        switch self {
        case .findNew:
            return .foregroundOnEmphasis
        case .connectWallet, .importFromWebsite, .importWallet:
            return .foregroundDefault
        }
    }
    var backgroundColor: UIColor {
        switch self {
        case .findNew:
            return .backgroundAccentEmphasis
        case .connectWallet, .importFromWebsite, .importWallet:
            return .backgroundMuted2
        }
    }
    var analyticsName: String { rawValue }
    
}

enum DomainsCollectionMintingState {
    case `default`, mintingPrimary, primaryDomainMinted
}
