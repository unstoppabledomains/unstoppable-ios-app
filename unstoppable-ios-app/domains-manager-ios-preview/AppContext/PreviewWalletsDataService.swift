//
//  PreviewWalletsDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

final class PreviewWalletsDataService: WalletsDataServiceProtocol {
   
    
    private(set) var wallets: [WalletEntity] = []
    @Published private(set) var selectedWallet: WalletEntity? = nil
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher { $selectedWallet }
    
    init() {
        wallets = MockEntitiesFabric.Wallet.mockEntities()
        selectedWallet = wallets.first
    }
    
    func setSelectedWallet(_ wallet: WalletEntity) {
        selectedWallet = wallet
    }
    
    func refreshDataForWallet(_ wallet: WalletEntity) async throws {
        
    }
    
}
