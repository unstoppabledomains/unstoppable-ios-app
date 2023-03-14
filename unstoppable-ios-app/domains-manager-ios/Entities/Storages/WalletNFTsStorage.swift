//
//  WalletNFTsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import Foundation

final class WalletNFTsStorage {
    
    private static let storageFileName = "wallet-nfts.data"
    
    private init() {}
    static var instance = WalletNFTsStorage()
    private var storage = SpecificStorage<[NFTResponse]>(fileName: WalletNFTsStorage.storageFileName)
    
    func getCachedNFTs() -> [NFTResponse] {
        storage.retrieve() ?? []
    }
    
    func getCachedNFTs(for walletAddress: HexAddress) -> [NFTResponse] {
        let pfpInfo = getCachedNFTs()
        
        return pfpInfo.filter({ $0.address == walletAddress })
    }
    
    func saveCachedNFTs(_ nfts: [NFTResponse]) {
        set(newNFTs: nfts)
    }
    
    private func set(newNFTs: [NFTResponse]) {
        storage.store(newNFTs)
    }
}
