//
//  WalletsDataServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

protocol WalletsDataServiceProtocol {
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher  { get }
    var selectedWallet: WalletEntity? { get }
    var wallets: [WalletEntity] { get }
    
    func setSelectedWallet(_ wallet: WalletEntity)
}
