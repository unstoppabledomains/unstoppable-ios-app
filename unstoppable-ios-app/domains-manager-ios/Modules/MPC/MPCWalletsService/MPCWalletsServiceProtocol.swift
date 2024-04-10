//
//  MPCWalletsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

protocol MPCWalletsServiceProtocol {
    func sendBootstrapCodeTo(email: String) async throws
    func setupMPCWalletWith(code: String,
                            recoveryPhrase: String) -> AsyncThrowingStream<SetupMPCWalletStep, Error>
    func signMessage(_ messageString: String, by wallet: MPCWalletMetadata) async throws -> String
}
