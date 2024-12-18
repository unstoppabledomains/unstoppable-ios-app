//
//  WalletDetails.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

enum WalletDetails { } // Namespace

extension WalletDetails {
    enum WalletAction: HomeWalletActionItem {
        
        var id: String {
            switch self {
            case .rename:
                return "send"
            case .backUp:
                return "backUp"
            case .more:
                return "more"
            case .mpc2FA:
                return "mpc2FA"
            }
        }
        
        case rename
        case backUp(WalletDisplayInfo.BackupState)
        case more([WalletSubAction])
        case mpc2FA(Bool)
        
        var title: String {
            switch self {
            case .rename:
                return String.Constants.rename.localized()
            case .backUp(let state):
                if case .backedUp = state {
                    return String.Constants.backedUp.localized()
                }
                return String.Constants.backUp.localized()
            case .more:
                return String.Constants.more.localized()
            case .mpc2FA(let isEnabled):
                return isEnabled ? String.Constants.mpc2FAEnabled.localized() : String.Constants.mpc2FAEnable.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .rename:
                return .brushSparkle
            case .backUp(let state):
                if case .backedUp = state {
                    return Image(uiImage: state.icon)
                }
                return .cloudIcon
            case .more:
                return .dotsIcon
            case .mpc2FA(let isEnabled):
                return isEnabled ? .shieldCheckmark : .shieldEmpty
            }
        }
        
        var tint: Color {
            switch self {
            case .backUp(let state):
                if case .backedUp = state {
                    return .foregroundSuccess
                }
                return .foregroundAccent
            case .mpc2FA(let isEnabled):
                return isEnabled ? .foregroundSuccess : .foregroundAccent
            default:
                return .foregroundAccent
            }
        }
        
        var subActions: [WalletSubAction] {
            switch self {
            case .backUp, .rename, .mpc2FA:
                return []
            case .more(let subActions):
                return subActions
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .rename:
                return .walletRename
            case .backUp:
                return .walletBackup
            case .more:
                return .more
            case .mpc2FA:
                return .mpc2FA
            }
        }
        
        var isDimmed: Bool {
            switch self {
            case .rename, .backUp, .more, .mpc2FA:
                return false
            }
        }
    }
    
    enum WalletSubAction: String, CaseIterable, HomeWalletSubActionItem {
        
        case privateKey
        case recoveryPhrase
        case removeWallet
        case disconnectWallet
        case mpcRecoveryKit
        
        var title: String {
            switch self {
            case .privateKey:
                return String.Constants.viewPrivateKey.localized()
            case .recoveryPhrase:
                return String.Constants.viewRecoveryPhrase.localized()
            case .removeWallet:
                return String.Constants.removeWallet.localized()
            case .disconnectWallet:
                return  String.Constants.disconnectWallet.localized()
            case .mpcRecoveryKit:
                return "Request recovery kit"
            }
        }
        
        var icon: Image {
            switch self {
            case .recoveryPhrase, .privateKey:
                return Image.systemDocOnDoc
            case .removeWallet, .disconnectWallet:
                return Image.trashIcon
            case .mpcRecoveryKit:
                return Image(systemName: "list.bullet.rectangle.portrait")
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .recoveryPhrase, .privateKey, .mpcRecoveryKit:
                return false
            case .removeWallet, .disconnectWallet:
                return true
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .recoveryPhrase, .privateKey:
                return .walletRecoveryPhrase
            case .removeWallet, .disconnectWallet:
                return .walletRemove
            case .mpcRecoveryKit:
                return .mpcRecoveryKit
            }
        }
    }
    
}
