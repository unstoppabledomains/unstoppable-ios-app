//
//  TestableMPCWalletsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 02.05.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableMPCWalletsService: MPCWalletsServiceProtocol {
    func setupMPCWalletWith(code: String, flow: domains_manager_ios.SetupMPCFlow) -> AsyncThrowingStream<domains_manager_ios.SetupMPCWalletStep, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
    
    func requestRecovery(password: String, by walletMetadata: domains_manager_ios.MPCWalletMetadata) async throws -> String {
        throw NSError()
    }
    
    func is2FAEnabled(for walletMetadata: domains_manager_ios.MPCWalletMetadata) throws -> Bool {
        throw NSError()
    }
    
    func request2FASetupDetails(for walletMetadata: domains_manager_ios.MPCWalletMetadata) async throws -> domains_manager_ios.MPCWallet2FASetupDetails {
        throw NSError()
    }
    
    func confirm2FAEnabled(for walletMetadata: domains_manager_ios.MPCWalletMetadata, code: String) async throws {
        
    }
    
    func disable2FA(for walletMetadata: domains_manager_ios.MPCWalletMetadata, code: String) async throws {
        
    }
    
 
    func getBalancesFor(walletMetadata: MPCWalletMetadata) async throws -> [WalletTokenPortfolio] {
        []
    }
    
    func canTransferAssets(symbol: String, chain: String, by walletMetadata: MPCWalletMetadata) -> Bool {
        true
    }
    
    func transferAssets(_ amount: Double, symbol: String, chain: String, destinationAddress: String, by walletMetadata: MPCWalletMetadata) async throws -> String {
        ""
    }
    
    func sendETHTransaction(data: String,
                            value: String,
                            chain: BlockchainType,
                            destinationAddress: String,
                            by walletMetadata: MPCWalletMetadata) async throws -> String {
        ""
    }
    
    func getTokens(for walletMetadata: MPCWalletMetadata) throws -> [BalanceTokenUIDescription] {
        []
    }
    
    func fetchGasFeeFor(_ amount: Double, symbol: String, chain: String, destinationAddress: String, by walletMetadata: MPCWalletMetadata) async throws -> Double {
        1
    }
    
    func sendBootstrapCodeTo(email: String) async throws {
        
    }
    
    func setupMPCWalletWith(code: String, credentials: MPCActivateCredentials) -> AsyncThrowingStream<SetupMPCWalletStep, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
    
    func signPersonalMessage(_ messageString: String, by walletMetadata: MPCWalletMetadata) async throws -> String {
        ""
    }
    
    func signTypedDataMessage(_ message: String, chain: BlockchainType, by walletMetadata: MPCWalletMetadata) async throws -> String {
        ""
    }
    
    
    func getBalancesFor(wallet: String, walletMetadata: MPCWalletMetadata) async throws -> [WalletTokenPortfolio] {
        []
    }
    
    
}

