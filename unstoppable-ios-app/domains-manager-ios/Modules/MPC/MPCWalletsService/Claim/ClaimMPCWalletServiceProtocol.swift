//
//  ClaimMPCWalletServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import Foundation

protocol ClaimMPCWalletServiceProtocol {
    func validateEmailIsAvailable(email: String) async throws -> Bool
    func sendVerificationCodeTo(email: String) async throws
    func runTakeover(credentials: MPCTakeoverCredentials) async throws
}
