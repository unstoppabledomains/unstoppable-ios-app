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
        private let storage = SpecificStorage<[UDWalletMetadata]>(fileName: MPCWalletsDefaultDataStorage.FBUDMPCWalletsStorageFileName)
        
        func storeAuthTokens(_ tokens: FB_UD_MPC.AuthTokens, for deviceId: String) throws {
            let data = try tokens.jsonDataThrowing()
            let key = getSecureStorageKeyFor(deviceId: deviceId)
            try secureStorage.setObject(data, forKey: key)
        }
        
        func retrieveAuthTokensFor(deviceId: String) throws -> FB_UD_MPC.AuthTokens {
            let key = getSecureStorageKeyFor(deviceId: deviceId)
            let data = try secureStorage.object(forKey: key)
            let authTokens = try AuthTokens.objectFromDataThrowing(data)
            return authTokens
        }
        
        func storeMetadata(_ metadata: FB_UD_MPC.UDWalletMetadata) throws {
            var storedMetadata = storage.retrieve() ?? []
            if let i = storedMetadata.firstIndex(where: { $0.deviceId == metadata.deviceId }) {
                storedMetadata[i] = metadata
            } else {
                storedMetadata.append(metadata)
            }
            storage.store(storedMetadata)
        }
        
        func retrieveMetadataFor(deviceId: String) throws -> FB_UD_MPC.UDWalletMetadata {
            let storedMetadata = storage.retrieve() ?? []
            guard let metadata = storedMetadata.first(where:{ $0.deviceId == deviceId }) else {
                throw MPCWalletsDefaultDataStorageError.metadataNotFound
            }
            
            return metadata
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
