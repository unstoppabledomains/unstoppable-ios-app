//
//  ClaimMPCWalletService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import Foundation

final class ClaimMPCWalletService {
    
    private let networkService = ClaimMPCWalletNetworkService()
    
}

// MARK: - ClaimMPCWalletServiceProtocol
extension ClaimMPCWalletService: ClaimMPCWalletServiceProtocol {
    func validateCredentialsForTakeover(credentials: MPCTakeoverCredentials) async throws -> Bool {
        do {
            try await validateUserExists(credentials: credentials)
            // There's already existing user with given email. 
            return false
        } catch NetworkLayerError.badResponseOrStatusCode(let code, _, _) where code == 404 { // 404 returned when email not in use hence available
            return true
        } catch {
            throw error
        }
    }
    
    func sendVerificationCodeTo(email: String) async throws {
        try await networkService.sendVerificationCodeTo(email: email)
    }
    
    func runTakeover(credentials: MPCTakeoverCredentials) async throws {
        try await networkService.registerWalletWith(credentials: credentials)
        
        for i in 0..<240 {
            do {
                try await validateUserExists(credentials: credentials)
                return
            } catch {  }
            await Task.sleep(seconds: 0.5)
        }
        
        throw ClaimMPCWalletServiceError.waitWalletClaimedTimeout
    }
}

// MARK: - Private methods
private extension ClaimMPCWalletService {
    func validateUserExists(credentials: MPCTakeoverCredentials) async throws {
        _ = try await networkService.getUserDetails(email: credentials.email)
    }
    
    enum ClaimMPCWalletServiceError: String, LocalizedError {
        case waitWalletClaimedTimeout
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
