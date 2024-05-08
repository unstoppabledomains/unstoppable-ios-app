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
            
            static var authURL: String { v1URL.appendingURLPathComponents("auth") }
            static var getCodeOnEmailURL: String { authURL.appendingURLPathComponents("bootstrap", "email") }
            static var submitCodeURL: String { authURL.appendingURLPathComponents("bootstrap") }
            static var devicesBootstrapURL: String { authURL.appendingURLPathComponents("devices", "bootstrap") }
            
            static var rpcMessagesURL: String { v1URL.appendingURLPathComponents("rpc", "messages") }
            
            static var tokensURL: String { v1URL.appendingURLPathComponents("auth", "tokens") }
            static var tokensSetupURL: String { tokensURL.appendingURLPathComponents("setup") }
            static var tokensConfirmURL: String { tokensURL.appendingURLPathComponents("confirm") }
            static var tokensVerifyURL: String { tokensURL.appendingURLPathComponents("verify") }
            static var tokensRefreshURL: String { tokensURL.appendingURLPathComponents("refresh") }
            static var tokensBootstrapURL: String { tokensURL.appendingURLPathComponents("bootstrap") }
            
            static var supportedBlockchainsURL: String { v1URL.appendingURLPathComponents("blockchain-assets") }
            
            static var accountsURL: String { v1URL.appendingURLPathComponents("accounts") }
            static func accountAssetsURL(accountId: String) -> String {
                accountsURL.appendingURLPathComponents(accountId, "assets")
            }
            static func assetURL(accountId: String, assetId: String) -> String {
                accountAssetsURL(accountId: accountId).appendingURLPathComponents(assetId)
            }
            static func assetSignaturesURL(accountId: String, assetId: String) -> String {
                assetURL(accountId: accountId, assetId: assetId).appendingURLPathComponents("signatures")
            }
            static func assetTransfersURL(accountId: String, assetId: String) -> String {
                assetURL(accountId: accountId, assetId: assetId).appendingURLPathComponents("transfers")
            }
            
            static var operationsURL: String { v1URL.appendingURLPathComponents("operations") }
            static func operationURL(operationId: String) -> String {
                operationsURL.appendingURLPathComponents(operationId)
            }
        }
    }
}
