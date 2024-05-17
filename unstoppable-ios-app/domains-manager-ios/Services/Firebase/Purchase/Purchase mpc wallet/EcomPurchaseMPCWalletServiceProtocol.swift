//
//  FirebasePurchaseMPCWalletServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation

protocol EcomPurchaseMPCWalletServiceProtocol {
    var cartStatusPublisher: Published<PurchaseMPCWalletCartStatus>.Publisher  { get }
    var isApplePaySupported: Bool { get }
    
    func authoriseWithEmail(_ email: String, password: String) async throws
    func authoriseWithGoogle() async throws
    func authoriseWithTwitter() async throws
    func authoriseWithWallet(_ wallet: UDWallet) async throws
    func reset() async
    func refreshCart() async throws
    
    func guestAuthWith(credentials: MPCPurchaseUDCredentials) async throws
    func purchaseMPCWallet() async throws
    func validateCredentialsForTakeover(credentials: MPCActivateCredentials) async throws -> Bool
    func runTakeover(credentials: MPCActivateCredentials) async throws
}
