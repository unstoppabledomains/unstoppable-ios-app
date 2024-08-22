//
//  PreviewClaimMPCWalletService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import Foundation

final class ClaimMPCWalletService {
    
}

// MARK: - ClaimMPCWalletServiceProtocol
extension ClaimMPCWalletService: ClaimMPCWalletServiceProtocol {
    func validateCredentialsForTakeover(credentials: MPCTakeoverCredentials) async throws -> Bool {
        true
    }
    
    func sendVerificationCodeTo(email: String) async throws {
        await Task.sleep(seconds: 0.5)        
    }
    
    func runTakeover(credentials: MPCTakeoverCredentials) async throws {
        await Task.sleep(seconds: 5)
    }
}
