//
//  UDWallet+RecoveryType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

extension UDWallet {
    var recoveryType: RecoveryType? {
        .init(walletType: type)
    }
    
    enum RecoveryType: Codable {
        case recoveryPhrase
        case privateKey
        
        init?(walletType: WalletType) {
            switch walletType {
            case .privateKeyEntered:
                self = .privateKey
            case .defaultGeneratedLocally, .generatedLocally, .mnemonicsEntered:
                self = .recoveryPhrase
            case .importedUnverified:
                return nil
            }
        }
    }
}
