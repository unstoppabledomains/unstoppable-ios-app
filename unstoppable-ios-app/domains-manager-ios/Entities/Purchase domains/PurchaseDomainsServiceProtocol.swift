//
//  PurchaseDomainsServiceProtocol.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

protocol PurchaseDomainsServiceProtocol {
    var cart: PurchaseDomainsCart { get }
    var cartPublisher: Published<PurchaseDomainsCart>.Publisher  { get }
    
    func searchForDomains(key: String) async throws -> [DomainToPurchase]
    func getSupportedWalletsToMint() async throws -> [PurchasedDomainsWalletDescription]
    
    func addDomainsToCart(_ domains: [DomainToPurchase]) async throws
    func removeDomainsFromCart(_ domains: [DomainToPurchase]) async throws
    func purchaseDomainsInTheCartAndMintTo(wallet: PurchasedDomainsWalletDescription) async throws
}
