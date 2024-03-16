//
//  MPCConnectionNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

protocol MPCConnectionNetworkService {
    func sendBootstrapCodeTo(email: String) async throws
    func submitBootstrapCode(_ code: String) async throws -> MPCBootstrapCodeSubmitResponse
    func authNewDeviceWith(requestId: String,
                           recoveryPhrase: String,
                           accessToken: String) async throws
    func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> MPCSetupTokenResponse
    func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws
    func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> MPCSuccessAuthResponse
    func verifyAccessToken(_ accessToken: String) async throws
}
