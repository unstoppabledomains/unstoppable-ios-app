//
//  PreviewEcomPurchaseMPCWalletService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation
import Combine

final class PreviewEcomPurchaseMPCWalletService: EcomPurchaseMPCWalletServiceProtocol {
    private var cart: PurchaseMPCWalletCart = PurchaseMPCWalletCart(totalPrice: 999,
                                                                    taxes: 0,
                                                                    storeCreditsAvailable: 0,
                                                                    promoCreditsAvailable: 0,
                                                                    appliedDiscountDetails: .init(storeCredits: 0,
                                                                                                  promoCredits: 0,
                                                                                                  others: 0)) {
        didSet {
            cartStatus = .ready(cart: cart)
        }
    }
    @Published var cartStatus: PurchaseMPCWalletCartStatus
    var cartStatusPublisher: Published<PurchaseMPCWalletCartStatus>.Publisher { $cartStatus }
    var isApplePaySupported: Bool { false }
    private var cancellables: Set<AnyCancellable> = []
    private var checkoutData: PurchaseDomainsCheckoutData
    
    init() {
        let preferencesService = PurchaseDomainsPreferencesStorage.shared
        checkoutData = preferencesService.checkoutData
        cartStatus = .ready(cart: cart)
        preferencesService.$checkoutData.publisher
            .sink { val in
                self.checkoutData = val
            }
            .store(in: &cancellables)
    }
    
    func purchaseMPCWallet() async throws {
        await Task.sleep(seconds: 2.2)
        throw NSError()
    }
    
    func guestAuthWith(credentials: MPCPurchaseUDCredentials) async throws {
        
    }
    
    func authoriseWithEmail(_ email: String, password: String) async throws {
        
    }
    
    func authoriseWithGoogle() async throws {
        
    }
    
    func authoriseWithTwitter() async throws {
        
    }
    
    func authoriseWithWallet(_ wallet: UDWallet) async throws {
        
    }
    
    func reset() async {
        
    }
    
    func refreshCart() async throws {
        
    }
    
    func validateCredentialsForTakeover(credentials: MPCTakeoverCredentials) async throws -> Bool {
        await Task.sleep(seconds: 1)
        return [true, false].randomElement()!
    }
    
    func runTakeover(credentials: MPCTakeoverCredentials) async throws {
        
    }
    
}
