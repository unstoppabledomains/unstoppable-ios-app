//
//  WalletInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit

struct WalletDisplayInfo: Hashable {
    let name: String
    let address: String
    let domainsCount: Int
    let source: Source
    let isBackedUp: Bool
    var isWithPrivateKey: Bool = false
    var reverseResolutionDomain: DomainDisplayInfo? = nil
    
    var backupState: BackupState {
        if isBackedUp {
            return .backedUp
        } else {
            switch source {
            case .locallyGenerated:
                return .locallyGeneratedNotBackedUp
            case .imported, .external:
                return .importedNotBackedUp
            }
        }
    }
    
    var isNameSet: Bool { name != address }
    var isConnected: Bool {
        switch source {
        case .locallyGenerated, .imported:
            return false
        case .external:
            return true
        }
    }

    var displayName: String {
        if isNameSet {
            return name
        } else {
            switch source {
            case .locallyGenerated, .imported:
                return address.walletAddressTruncated
            case .external(let name, _):
                return name
            }
        }
    }
    
    var walletSourceName: String {
        switch source {
        case .locallyGenerated:
            return String.Constants.vault.localized()
        case .imported, .external:
            return String.Constants.wallet.localized()
        }
    }
}

extension WalletDisplayInfo {
    init?(wallet: UDWallet, domainsCount: Int, reverseResolutionDomain: DomainDisplayInfo? = nil) {
        if wallet.walletState == .externalLinked {
            guard let externalWallet = wallet.getExternalWallet(),
                  let walletMake = externalWallet.make else { return nil }
            
            self.name = wallet.aliasName
            self.address = wallet.address
            self.domainsCount = domainsCount
            self.source = .external(externalWallet.name, walletMake)
            self.isBackedUp = false
            self.isWithPrivateKey = false
        } else {
            self.name = wallet.aliasName
            self.address = wallet.address
            self.domainsCount = domainsCount
            self.isBackedUp = wallet.hasBeenBackedUp == true
            switch wallet.type {
            case .generatedLocally, .defaultGeneratedLocally:
                self.source = .locallyGenerated
                self.isWithPrivateKey = false
            case .privateKeyEntered, .mnemonicsEntered, .importedUnverified:
                self.source = .imported
                self.isWithPrivateKey = wallet.type == .privateKeyEntered
            }
        }
        self.reverseResolutionDomain = reverseResolutionDomain
    }
}

// MARK: - BackupState
extension WalletDisplayInfo {
    enum BackupState {
        case backedUp, locallyGeneratedNotBackedUp, importedNotBackedUp
        
        var icon: UIImage {
            switch self {
            case .backedUp, .importedNotBackedUp:
                return .checkCircle
            case .locallyGeneratedNotBackedUp:
                return .warningIconLarge
            }
        }
        
        var tintColor: UIColor {
            switch self {
            case .backedUp:
                return .foregroundSuccess
            case .locallyGeneratedNotBackedUp:
                return .foregroundWarning
            case .importedNotBackedUp:
                return .foregroundSecondary
            }
        }
    }
}

// MARK: - Source
extension WalletDisplayInfo {
    enum Source: Hashable {
        case locallyGenerated, imported, external(_ name: String, _ walletMake: ExternalWalletMake)
        
        var displayIcon: UIImage {
            switch self {
            case .locallyGenerated:
                return .udWalletListIcon
            case .external(_, let walletMake):
                return walletMake.icon
            case .imported:
                return .walletIcon
            }
        }
    }
}

extension Array where Element == WalletDisplayInfo {
    func managedWalletsSorted() -> [Element] {
        self.sorted { lhs, rhs in
            switch (lhs.source, rhs.source) {
            case (.locallyGenerated, .imported):
                return true
            default:
                return false
            }
        }
    }
}
