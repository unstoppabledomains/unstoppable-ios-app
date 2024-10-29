//
//  MPCWalletProviderSubserviceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

protocol MPCWalletProviderSubServiceProtocol {
    var provider: MPCWalletProvider { get }
    
    func sendBootstrapCodeTo(email: String) async throws
    func setupMPCWalletWith(code: String,
                            flow: SetupMPCFlow) -> AsyncThrowingStream<SetupMPCWalletStep, Error>
    func signPersonalMessage(_ messageString: String,
                             chain: BlockchainType,
                             by walletMetadata: MPCWalletMetadata) async throws -> String
    func signTypedDataMessage(_ message: String,
                              chain: BlockchainType,
                              by walletMetadata: MPCWalletMetadata) async throws -> String
    func getBalancesFor(walletMetadata: MPCWalletMetadata) async throws -> [WalletTokenPortfolio]
    
    func canTransferAssets(symbol: String,
                           chain: String,
                           by walletMetadata: MPCWalletMetadata) -> Bool
    func transferAssets(_ amount: Double,
                        symbol: String,
                        chain: String,
                        destinationAddress: String,
                        by walletMetadata: MPCWalletMetadata) async throws -> String
    func sendETHTransaction(data: String,
                            value: String,
                            chain: BlockchainType,
                            destinationAddress: String,
                            by walletMetadata: MPCWalletMetadata) async throws -> String
    func getTokens(for walletMetadata: MPCWalletMetadata) throws -> [BalanceTokenUIDescription]
    func fetchGasFeeFor(_ amount: Double,
                        symbol: String,
                        chain: String,
                        destinationAddress: String,
                        by walletMetadata: MPCWalletMetadata) async throws -> Double
    /// Request recovery kit for given wallet
    /// - Returns: Email from attached to wallet account
    func requestRecovery(for walletMetadata: MPCWalletMetadata,
                         password: String) async throws -> String

    // 2FA
    func is2FAEnabled(for walletMetadata: MPCWalletMetadata) throws -> Bool
    func request2FASetupDetails(for walletMetadata: MPCWalletMetadata) async throws -> MPCWallet2FASetupDetails
    func confirm2FAEnabled(for walletMetadata: MPCWalletMetadata, token: String) async throws
}
