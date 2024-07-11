//
//  FB_UD_MPCAccountBalance.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

extension FB_UD_MPC {
    struct WalletAccountAsset: Codable {
        let type: String
        let id: String
        let address: String
        let balance: Balance?
        let blockchainAsset: BlockchainAsset
        
        private enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id
            case address
            case balance
            case blockchainAsset
        }
        
        struct Balance: Codable {
            let total: String
            let decimals: Int
        }
   
        func createTokenUIDescription() -> BalanceTokenUIDescription {
            var symbol = blockchainAsset.symbol
            var chain: String
            var parentSymbol: String?
            var name = blockchainAsset.name
            
            if let resolvedChain = WalletAccountAsset.symbolFor(mpcID: blockchainAsset.blockchain.id) {
                chain = resolvedChain
                if resolvedChain != symbol { // Token
                    parentSymbol = resolvedChain
                }
                
                /// Adjust appearance of Base coin specifically.
                if blockchainAsset.symbol == BlockchainType.Ethereum.shortCode,
                   blockchainAsset.blockchain.id == Constants.baseChainSymbol {
                    symbol = "BASE"
                    name = "Base"
                }
            } else {
                chain = symbol // Coin
            }
            
            var token = BalanceTokenUIDescription(address: address,
                                                  chain: chain,
                                                  symbol: symbol,
                                                  name: name,
                                                  balance: 0,
                                                  balanceUsd: 0)
            
            if let parentSymbol {
                token.parent = .init(symbol: parentSymbol,
                                     balance: 0.0)
            }
            
            return token
        }
        
        private static let mpcSymbolToIDMap: [String : String] = ["ETH":"ETHEREUM",
                                                                  "MATIC":"POLYGON",
                                                                  "SOL":"SOLANA",
                                                                  "BTC":"BITCOIN",
                                                                  "BASE":"BASE"]
        
        static func mpcIDFor(symbol: String) -> String? {
            mpcSymbolToIDMap[symbol]
        }
        
        static func symbolFor(mpcID: String) -> String? {
            mpcSymbolToIDMap.first(where: { $0.value == mpcID })?.key
        }
    }
    
    struct WalletAccountAssetsResponse: Codable {
        let items: [WalletAccountAsset]
        let next: String?
    }
}

extension Array where Element == FB_UD_MPC.WalletAccountAsset {
    func findWith(symbol: String, chain: String) -> Element? {
        guard let id = FB_UD_MPC.WalletAccountAsset.mpcIDFor(symbol: chain) else { return nil }
        
        // TODO: - Check for $0.blockchainAsset.blockchain.symbol when BE ready
        return first(where: { $0.blockchainAsset.symbol == symbol && $0.blockchainAsset.blockchain.id == id })
    }
}
