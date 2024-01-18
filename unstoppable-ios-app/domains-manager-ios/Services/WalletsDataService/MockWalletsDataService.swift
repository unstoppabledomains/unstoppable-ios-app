//
//  MockWalletsDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

final class MockWalletsDataService: WalletsDataServiceProtocol {
    
    private(set) var wallets: [WalletEntity] = []
    @Published private(set) var selectedWallet: WalletEntity? = nil
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher { $selectedWallet }
    
    func setSelectedWallet(_ wallet: WalletEntity) {
        
    }
}
