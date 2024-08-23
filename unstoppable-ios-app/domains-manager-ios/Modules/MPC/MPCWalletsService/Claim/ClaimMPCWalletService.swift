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
        do {
            try await networkService.registerWalletWith(credentials: credentials)
            try await waitForNewWalletIsReady(credentials: credentials)
        } catch {
            if error.isNetworkError(withCode: 429) {
                // Request to create wallet already sent, need to wait for it to be ready
                try await waitForNewWalletIsReady(credentials: credentials)
                return
            }
            throw error
        }
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
    
    func waitForNewWalletIsReady(credentials: MPCTakeoverCredentials) async throws {
        let secondsInMinutes: Double = 60.0
        let minutesToWait: Double = 3.0
        let checkStatusFrequency: Double = 0.5
        let checkStatusCyclesCount = Int((secondsInMinutes * minutesToWait) / checkStatusFrequency)
        
        for i in 0..<checkStatusCyclesCount {
            do {
                try await validateUserExists(credentials: credentials)
                return
            } catch {  }
            await Task.sleep(seconds: checkStatusFrequency)
        }
        
        throw ClaimMPCWalletServiceError.waitWalletClaimedTimeout
    }
}
