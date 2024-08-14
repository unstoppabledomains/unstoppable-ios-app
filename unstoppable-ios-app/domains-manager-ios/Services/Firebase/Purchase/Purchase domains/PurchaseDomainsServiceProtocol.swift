//
//  PurchaseDomainsServiceProtocol.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

protocol PurchaseDomainsServiceProtocol {
    var cartStatusPublisher: Published<PurchaseDomainCartStatus>.Publisher  { get }
    var isApplePaySupported: Bool { get }
    
    func searchForDomains(key: String,
                          tlds: Set<String>) async throws -> [DomainToPurchase]
    func aiSearchForDomains(hint: String) async throws -> [DomainToPurchase]
    func getDomainsSuggestions(hint: String, tlds: Set<String>) async throws -> [DomainToPurchase]
    
    func authoriseWithWallet(_ wallet: UDWallet, toPurchaseDomains domains: [DomainToPurchase]) async throws
    func setDomainsToPurchase(_ domains: [DomainToPurchase]) async throws
    func getSupportedWalletsToMint() async throws -> [PurchasedDomainsWalletDescription]
    func getPreferredWalletToMint() async throws -> PurchasedDomainsWalletDescription
    func reset() async
    
    func refreshCart() async throws 
    func addDomainsToCart(_ domains: [DomainToPurchase]) async throws
    func removeDomainsFromCart(_ domains: [DomainToPurchase]) async throws
    func purchaseDomainsInTheCartAndMintTo(wallet: PurchasedDomainsWalletDescription) async throws
}
