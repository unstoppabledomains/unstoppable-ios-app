//
//  MPCConnectionNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    protocol MPCConnectionNetworkService {
        func sendBootstrapCodeTo(email: String) async throws
        func submitBootstrapCode(_ code: String) async throws -> BootstrapCodeSubmitResponse
        func authNewDeviceWith(requestId: String,
                               recoveryPhrase: String,
                               accessToken: String) async throws
        func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> SetupTokenResponse
        func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws
        func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> SuccessAuthResponse
        func verifyAccessToken(_ accessToken: String) async throws
        
        func refreshToken(_ refreshToken: String) async throws -> SuccessAuthResponse
    }
}
