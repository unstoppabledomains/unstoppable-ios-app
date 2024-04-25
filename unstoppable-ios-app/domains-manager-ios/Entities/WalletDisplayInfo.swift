//
//  WalletInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit

struct WalletDisplayInfo: Hashable, Equatable, Codable {
    let name: String
    let address: String
    var domainsCount: Int
    var udDomainsCount: Int
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
                // TODO: - MPC
            case .imported, .external, .mpc:
                return .importedNotBackedUp
            }
        }
    }
    
    var isNameSet: Bool { name != address }
    var isConnected: Bool {
        switch source {
            // TODO: - MPC
        case .locallyGenerated, .imported, .mpc:
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
                // TODO: - MPC
            case .locallyGenerated, .imported, .mpc:
                return address.walletAddressTruncated
            case .external(let name, _):
                return name
            }
        }
    }
    
    var walletSourceName: String {
        String.Constants.wallet.localized()
    }
}

extension WalletDisplayInfo {
    init?(wallet: UDWallet,
          domainsCount: Int,
          udDomainsCount: Int,
          reverseResolutionDomain: DomainDisplayInfo? = nil) {
        
        self.isBackedUp = wallet.hasBeenBackedUp == true
        switch wallet.type {
        case .generatedLocally, .defaultGeneratedLocally:
            self.source = .locallyGenerated
            self.isWithPrivateKey = false
        case .privateKeyEntered, .mnemonicsEntered, .importedUnverified:
            self.source = .imported
            self.isWithPrivateKey = wallet.type == .privateKeyEntered
        case .mpc:
            self.source = .mpc
            self.isWithPrivateKey = false
        case .externalLinked:
            guard let externalWallet = wallet.getExternalWallet(),
                  let walletMake = externalWallet.make else { return nil }

            self.source = .external(externalWallet.name, walletMake)
            self.isWithPrivateKey = false
        }
        
        self.name = wallet.aliasName
        self.address = wallet.address
        self.reverseResolutionDomain = reverseResolutionDomain
        self.domainsCount = domainsCount
        self.udDomainsCount = udDomainsCount
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
    enum Source: Hashable, Codable {
        case locallyGenerated, imported, external(_ name: String, _ walletMake: ExternalWalletMake)
        case mpc
        
        var displayIcon: UIImage {
            switch self {
            case .external(_, let walletMake):
                return walletMake.icon
            case .imported, .locallyGenerated:
                return .walletExternalIcon
            case .mpc:
                return .shieldKeyhole
            }
        }
        
        var canBeBackedUp: Bool {
            switch self {
            case .locallyGenerated, .imported:
                true
            case .external, .mpc:
                false
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
