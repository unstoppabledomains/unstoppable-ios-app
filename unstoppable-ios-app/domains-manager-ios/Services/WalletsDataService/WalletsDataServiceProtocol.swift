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
    var walletsPublisher: Published<[WalletEntity]>.Publisher  { get }
    var wallets: [WalletEntity] { get }
    
    func setSelectedWallet(_ wallet: WalletEntity?)
    func refreshDataForWallet(_ wallet: WalletEntity) async throws
    func refreshDataForWalletDomain(_ domainName: DomainName) async throws
    func didChangeEnvironment()
    
    func didPurchaseDomains(_ purchasedDomains: [PendingPurchasedDomain],
                            pendingProfiles: [DomainProfilePendingChanges]) async
    func didMintDomainsWith(domainNames: [String],
                            to wallet: WalletEntity) -> [MintingDomain] 
}
