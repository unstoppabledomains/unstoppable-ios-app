//
//  SendCryptoAsset.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

enum SendCryptoAsset { }

extension SendCryptoAsset {
    struct InitialData: Identifiable {
        
        var id: String { sourceWallet.id }
        
        let sourceWallet: WalletEntity
    }
}

extension SendCryptoAsset {
    enum AssetType: String, Identifiable, CaseIterable, UDTabPickable {
        
        var id: String { rawValue }
        
        case tokens, domains
        
        var title: String {
            switch self {
            case .tokens:
                String.Constants.tokens.localized()
            case .domains:
                String.Constants.domains.localized()
            }
        }
    }
}
