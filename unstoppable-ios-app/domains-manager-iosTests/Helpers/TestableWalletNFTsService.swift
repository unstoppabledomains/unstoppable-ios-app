//
//  TestableWalletNFTsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableWalletNFTsService: WalletNFTsServiceProtocol {
    func fetchNFTsFor(walletAddress: HexAddress) async throws -> [NFTModel] {
        []
    }
    
    func addListener(_ listener: any WalletNFTsServiceListener) {
        
    }
    
    func removeListener(_ listener: any WalletNFTsServiceListener) {
        
    }
    
    
}
