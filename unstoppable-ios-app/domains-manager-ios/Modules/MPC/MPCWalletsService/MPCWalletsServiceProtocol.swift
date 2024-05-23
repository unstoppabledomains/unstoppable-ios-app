//
//  MPCWalletsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

protocol MPCWalletsServiceProtocol {
    func sendBootstrapCodeTo(email: String) async throws
    func setupMPCWalletWith(email: String,
                            code: String,
                            recoveryPhrase: String) -> AsyncThrowingStream<SetupMPCWalletStep, Error>
    func signMessage(_ messageString: String, by walletMetadata: MPCWalletMetadata) async throws -> String
    func getBalancesFor(walletMetadata: MPCWalletMetadata) async throws -> [WalletTokenPortfolio]
    
    func canTransferAssets(symbol: String,
                           chain: String,
                           by walletMetadata: MPCWalletMetadata) -> Bool
    func transferAssets(_ amount: Double,
                        symbol: String,
                        chain: String,
                        destinationAddress: String,
                        by walletMetadata: MPCWalletMetadata) async throws -> String
    func getTokens(for walletMetadata: MPCWalletMetadata) throws -> [BalanceTokenUIDescription]
    func fetchGasFeeFor(_ amount: Double,
                        symbol: String,
                        chain: String,
                        destinationAddress: String,
                        by walletMetadata: MPCWalletMetadata) async throws -> Double
}

@MainActor
protocol MPCWalletsUIHandler {
    func askToReconnectMPCWallet(_ reconnectData: MPCWalletReconnectData) async
}

struct MPCWalletReconnectData {
    let wallet: UDWallet
}
