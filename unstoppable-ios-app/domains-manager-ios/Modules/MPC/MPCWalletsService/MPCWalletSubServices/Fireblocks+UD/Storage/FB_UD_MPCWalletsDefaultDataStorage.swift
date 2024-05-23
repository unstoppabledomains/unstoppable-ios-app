//
//  FB_UD_MPCWalletsDefaultDataStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

extension FB_UD_MPC {
    struct MPCWalletsDefaultDataStorage: MPCWalletsDataStorage {
        
        static let FBUDMPCWalletsStorageFileName = "fb-ud-mpc-wallets.data"
        
        private let secureStorage: ValetProtocol = FB_UD_MPC.ValetStorage()
        private let storage = SpecificStorage<[ConnectedWalletAccountsDetails]>(fileName: MPCWalletsDefaultDataStorage.FBUDMPCWalletsStorageFileName)
        
        func storeAuthTokens(_ tokens: AuthTokens, for deviceId: String) throws {
            logMPC("\n\n\nWill store auth tokens.\nAccess token expire: \(tokens.accessToken.expirationDate).\nRefresh token expire: \(tokens.refreshToken.expirationDate).\nBootstrap token expire: \(tokens.bootstrapToken.expirationDate)\n\n\n")
            let data = try tokens.jsonDataThrowing()
            let key = getSecureStorageKeyFor(deviceId: deviceId)
            try secureStorage.setObject(data, forKey: key)
        }
        
        func clearAuthTokensFor(deviceId: String) throws {
            let key = getSecureStorageKeyFor(deviceId: deviceId)
            try secureStorage.removeObject(forKey: key)
        }

        func retrieveAuthTokensFor(deviceId: String) throws -> AuthTokens {
            let key = getSecureStorageKeyFor(deviceId: deviceId)
            let data = try secureStorage.object(forKey: key)
            let authTokens = try AuthTokens.objectFromDataThrowing(data)
            return authTokens
        }
        
        func storeAccountsDetails(_ accountsDetails: ConnectedWalletAccountsDetails) throws {
            var storedDetails = storage.retrieve() ?? []
            if let i = storedDetails.firstIndex(where: { $0.deviceId == accountsDetails.deviceId }) {
                storedDetails[i] = accountsDetails
            } else {
                storedDetails.append(accountsDetails)
            }
            storage.store(storedDetails)
        }
        
        func clearAccountsDetailsFor(deviceId: String) throws {
            var storedDetails = storage.retrieve() ?? []
            storedDetails.removeAll(where: { $0.deviceId == deviceId })
            storage.store(storedDetails)
        }

        func retrieveAccountsDetailsFor(deviceId: String) throws -> ConnectedWalletAccountsDetails {
            let storedDetails = storage.retrieve() ?? []
            guard let details = storedDetails.first(where:{ $0.deviceId == deviceId }) else {
                throw MPCWalletsDefaultDataStorageError.metadataNotFound
            }
            
            return details
        }
        
        enum MPCWalletsDefaultDataStorageError: String, LocalizedError {
            case metadataNotFound
            
            public var errorDescription: String? {
                return rawValue
            }
        }
        
        private func getSecureStorageKeyFor(deviceId: String) -> String {
            "auth_tokens_\(deviceId)"
        }
    }
}
