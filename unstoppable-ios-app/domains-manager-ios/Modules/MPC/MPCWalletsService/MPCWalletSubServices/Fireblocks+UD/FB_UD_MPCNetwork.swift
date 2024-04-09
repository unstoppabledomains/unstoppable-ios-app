//
//  MPCNetwork.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2024.
//

import Foundation

extension FB_UD_MPC {
    enum MPCNetwork {
        enum URLSList {
            static var baseURL: String {
                "https://api.ud-staging.com" // NetworkConfig.migratedBaseUrl
            }
            
            static var v1URL: String { baseURL.appendingURLPathComponents("wallet", "v1") }
            
            static var tempGetCodeURL: String { v1URL.appendingURLPathComponents("admin", "auth", "bootstrap-code") }
            static var submitCodeURL: String { v1URL.appendingURLPathComponents("auth", "bootstrap") }
            static var rpcMessagesURL: String { v1URL.appendingURLPathComponents("rpc", "messages") }
            static var devicesBootstrapURL: String { v1URL.appendingURLPathComponents("auth", "devices", "bootstrap") }
            
            static var tokensURL: String { v1URL.appendingURLPathComponents("auth", "tokens") }
            static var tokensSetupURL: String { tokensURL.appendingURLPathComponents("setup") }
            static var tokensConfirmURL: String { tokensURL.appendingURLPathComponents("confirm") }
            static var tokensVerifyURL: String { tokensURL.appendingURLPathComponents("verify") }
            static var tokensRefreshURL: String { tokensURL.appendingURLPathComponents("refresh") }
            
            static var accountsURL: String { v1URL.appendingURLPathComponents("accounts") }
            static func accountAssetsURL(accountId: String) -> String {
                accountsURL.appendingURLPathComponents(accountId, "assets")
            }
        }
    }
}
