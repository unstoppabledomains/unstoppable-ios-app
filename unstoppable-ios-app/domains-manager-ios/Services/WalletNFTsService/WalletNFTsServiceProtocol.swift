//
//  WalletNFTsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

protocol WalletNFTsServiceProtocol {
    func getImageNFTsFor(domainName: String) async throws -> [NFTModel]
    @discardableResult
    func refreshNFTsFor(domainName: String) async throws -> [NFTModel]
    
    // Listeners
    func addListener(_ listener: WalletNFTsServiceListener)
    func removeListener(_ listener: WalletNFTsServiceListener)
}

protocol WalletNFTsServiceListener: AnyObject {
    func didRefreshNFTs(_ nfts: [NFTModel], for domainName: DomainName)
}

final class WalletNFTsServiceListenerHolder: Equatable {
    
    weak var listener: WalletNFTsServiceListener?
    
    init(listener: WalletNFTsServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: WalletNFTsServiceListenerHolder, rhs: WalletNFTsServiceListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
