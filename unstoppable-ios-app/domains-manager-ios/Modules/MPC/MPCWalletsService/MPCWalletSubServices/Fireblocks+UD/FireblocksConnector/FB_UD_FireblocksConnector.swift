//
//  MPCConnector.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    protocol FireblocksConnectorProtocol {
        func requestJoinExistingWallet() async throws -> String
        func stopJoinWallet()
        func waitForKeyIsReady() async throws
        func signTransactionWith(txId: String) async throws
        func getLogsURLs() -> URL?
    }
}
