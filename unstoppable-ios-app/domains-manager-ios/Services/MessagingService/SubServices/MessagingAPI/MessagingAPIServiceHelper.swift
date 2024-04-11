//
//  MessagingAPIServiceHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import XMTPiOS

struct MessagingAPIServiceHelper {
    static func getXMTPConversationFromChat(_ chat: MessagingChat,
                                             client: XMTPiOS.Client) throws -> XMTPiOS.Conversation {
        let metadata: XMTPEnvironmentNamespace.ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
        return metadata.encodedContainer.decode(with: client)
    }
    
    static func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        let address = wallet.normalized
        guard let wallet = appContext.walletsDataService.wallets.findWithAddress(address),
              let domain = wallet.domains.first?.toDomainItem() else {
            throw MessagingHelperError.noDomainForWallet
        }
        
        return domain
    }
    
    static func getWalletEntity(for walletAddress: HexAddress) throws -> WalletEntity {
        guard let wallet = appContext.walletsDataService.wallets.findWithAddress(walletAddress) else {
            throw MessagingHelperError.walletNotFound
        }
        
        return wallet
    }
    
    static func decodeServiceMetadata<T: Codable>(from data: Data?) throws -> T {
        guard let data else {
            throw MessagingHelperError.failedToDecodeServiceData
        }
        guard let serviceMetadata = T.objectFromData(data) else {
            throw MessagingHelperError.failedToDecodeServiceData
        }
        
        return serviceMetadata
    }
    
    static func uploadDataToWeb3Storage(_ data: Data,
                                 ofType type: String,
                                 by wallet: HexAddress) async throws -> URL {
        let domain = try await MessagingAPIServiceHelper.getAnyDomainItem(for: wallet)
        let response = try await NetworkService().uploadRemoteAttachment(for: domain,
                                                                         base64: data.base64EncodedString(),
                                                                         type: type)
        return response.url
    }
    
    
    enum MessagingHelperError: String, LocalizedError {
        case noDomainForWallet
        case failedToDecodeServiceData
        case walletNotFound
        
        public var errorDescription: String? { rawValue }
    }
}
