//
//  WalletNFTsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import Foundation

final class DomainNFTsStorage {
    
    private static let storageFileName = "domain-nfts.data"
    
    private init() {}
    static var instance = DomainNFTsStorage()
    private var storage = SpecificStorage<[NFTModel]>(fileName: DomainNFTsStorage.storageFileName)
    
    func getCachedNFTs() -> [NFTModel] {
        storage.retrieve() ?? []
    }
    
    func saveCachedNFTs(_ nfts: [NFTModel]) {
        set(newNFTs: nfts)
    }
    
    private func set(newNFTs: [NFTModel]) {
        storage.store(newNFTs)
    }
}
