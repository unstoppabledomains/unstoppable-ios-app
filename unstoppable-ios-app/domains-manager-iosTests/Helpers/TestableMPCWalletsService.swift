//
//  TestableMPCWalletsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 02.05.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableMPCWalletsService: MPCWalletsServiceProtocol {
    func sendBootstrapCodeTo(email: String) async throws {
        
    }
    
    func setupMPCWalletWith(code: String, recoveryPhrase: String) -> AsyncThrowingStream<SetupMPCWalletStep, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
    
    func signMessage(_ messageString: String, by walletMetadata: domains_manager_ios.MPCWalletMetadata) async throws -> String {
        ""
    }
    
    func getBalancesFor(wallet: String, walletMetadata: domains_manager_ios.MPCWalletMetadata) async throws -> [domains_manager_ios.WalletTokenPortfolio] {
        []
    }
    
    
}

