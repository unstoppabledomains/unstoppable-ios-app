//
//  FB_UD_MPCAccount.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

extension FB_UD_MPC {
    struct WalletAccount: Codable {
        
        let type: String
        let id: String

        enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id
        }
        
    }
    
    struct WalletAccountsResponse: Codable {
        let items: [WalletAccount]
        let next: String?
    }
}
