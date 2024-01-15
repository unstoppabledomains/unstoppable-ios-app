//
//  PreviewWalletNFTsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import Foundation

final class PreviewWalletNFTsService {
    
}

// MARK: - Open methods
extension PreviewWalletNFTsService: WalletNFTsServiceProtocol {
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
