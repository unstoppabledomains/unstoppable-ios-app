//
//  PreviewWalletNFTsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

final class WalletNFTsService {
    
}

// MARK: - WalletNFTsServiceProtocol
extension WalletNFTsService: WalletNFTsServiceProtocol {
    func getImageNFTsFor(domainName: String) async throws -> [NFTModel] {
        []
    }
    
    func refreshNFTsFor(domainName: String) async throws -> [NFTModel] {
        []
    }
    
    func addListener(_ listener: WalletNFTsServiceListener) {
        
    }
    
    func removeListener(_ listener: WalletNFTsServiceListener) {
        
    }
}
