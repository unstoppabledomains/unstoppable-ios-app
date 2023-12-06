//
//  MockFirebaseInteractionService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.10.2023.
//

import UIKit
import Combine

final class MockFirebaseInteractionsService {
    
    @Published var isAuthorized: Bool = true
    var isAuthorizedPublisher: Published<Bool>.Publisher { $isAuthorized }
    
    private var cart: PurchaseDomainsCart = .empty {
        didSet {
            cartStatus = .ready(cart: cart)
        }
    }
    @Published var cartStatus: PurchaseDomainCartStatus = .ready(cart: MockFirebaseInteractionsService.createMockCart())
    var cartStatusPublisher: Published<PurchaseDomainCartStatus>.Publisher { $cartStatus }
    
    private var cancellables: Set<AnyCancellable> = []
    private var checkoutData: PurchaseDomainsCheckoutData
    
    init() {
        let preferencesService = PurchaseDomainsPreferencesStorage.shared
        checkoutData = preferencesService.checkoutData
        preferencesService.$checkoutData.publisher
            .sink { val in
                self.checkoutData = val
                self.updateCart()
            }
            .store(in: &cancellables)
    }
    
}

// MARK: - FirebaseAuthenticationServiceProtocol
extension MockFirebaseInteractionsService: FirebaseAuthenticationServiceProtocol {
    func authorizeWith(email: String, password: String) async throws {
        try await authorize()
    }
    
    func authorizeWithGoogle(in viewController: UIWindow) async throws {
        try await authorize()
    }
    
    func authorizeWithTwitter(in viewController: UIViewController) async throws {
        try await authorize()
    }
    
    func authorizeWith(wallet: UDWallet) async throws {
        try await authorize()
    }
    
    func getUserProfile() async throws -> FirebaseUser {
        .init(email: "qq@qq.qq")
    }
    
    func logout() {
        isAuthorized = false
    }
    
    // Listeners
    func addListener(_ listener: FirebaseAuthenticationServiceListener) { }
    func removeListener(_ listener: FirebaseAuthenticationServiceListener) { }
}

// MARK: - PurchaseDomainsServiceProtocol
extension MockFirebaseInteractionsService: PurchaseDomainsServiceProtocol {
    func searchForDomains(key: String) async throws -> [DomainToPurchase] {
        try await Task.sleep(seconds: 0.5)
        let key = key.lowercased()
        let tlds = ["x", "crypto", "nft", "wallet", "polygon", "dao", "888", "blockchain", "go", "bitcoin"]
        let prices = [40000, 20000, 8000, 4000, 500]
        return tlds.map { DomainToPurchase(name: "\(key).\($0)", price: prices.randomElement()!, metadata: nil)}
    }
    
    func getDomainsSuggestions(hint: String?) async throws -> [DomainToPurchaseSuggestion] {
        try await Task.sleep(seconds: 0.4)
        
        return [.init(name: "oleg"),
                .init(name: "39993"),
                .init(name: "explorevista")]
    }
    
    func addDomainsToCart(_ domains: [DomainToPurchase]) async throws {
        cart.domains.append(contentsOf: domains)
        updateCart()
    }
    
    func removeDomainsFromCart(_ domains: [DomainToPurchase]) async throws {
        let names = domains.map { $0.name }
        cart.domains.removeAll(where: { names.contains($0.name) })
        updateCart()
    }
    
    func getSupportedWalletsToMint() async throws -> [PurchasedDomainsWalletDescription] {
        let userWallets = try await loadUserCryptoWallets()
        return userWallets.map { PurchasedDomainsWalletDescription(address: $0.address, metadata: $0.jsonData()) }
    }
    
    func purchaseDomainsInTheCartAndMintTo(wallet: PurchasedDomainsWalletDescription) async throws {
        
    }
    
    func refreshCart() async throws { }
    
    func authoriseWithWallet(_ wallet: UDWallet, toPurchaseDomains domains: [DomainToPurchase]) async throws {
        cartStatus = .ready(cart: .empty)
        updateCart()
    }
    
    func reset() async {
        cartStatus = .ready(cart: .empty)
        updateCart()
    }
}

// MARK: - FirebaseDomainsServiceProtocol
extension MockFirebaseInteractionsService: FirebaseDomainsServiceProtocol {
    func getCachedDomains() -> [FirebaseDomain] {
        []
    }
    func getParkedDomains() async throws -> [FirebaseDomain] {
        []
    }
    func clearParkedDomains() {
        
    }
}

// MARK: - Private methods
private extension MockFirebaseInteractionsService {
    func authorize() async throws {
        try? await Task.sleep(seconds: 0.4)
        isAuthorized = true
    }
    
    func loadUserCryptoWallets() async throws -> [FirebasePurchaseDomainsService.UDUserAccountCryptWallet] {
        let wallets = appContext.udWalletsService.getUserWallets()
        return wallets.map { FirebasePurchaseDomainsService.UDUserAccountCryptWallet(id: 1, address: $0.address) }
//        [.init(id: 1605, address: "0xc4a748796805dfa42cafe0901ec182936584cc6e"),
//         .init(id: 1606, address: "0x8ed92xjd2793yenx837g3847d3n4dx9h")]
    }
    
    func updateCart() {
        cart.totalPrice = cart.domains.reduce(0, { $0 + $1.price })
        let storeCredits = checkoutData.isStoreCreditsOn ? 100 : 0
        let promoCredits = checkoutData.isPromoCreditsOn ? 2000 : 0
        let otherDiscounts = checkoutData.discountCode.isEmpty ? 0 : cart.totalPrice / 3
        cart.appliedDiscountDetails = .init(storeCredits: storeCredits, 
                                            promoCredits: promoCredits,
                                            others: otherDiscounts)
        if !checkoutData.usaZipCode.isEmpty {
            let taxes = 200
            cart.taxes = taxes
            cart.totalPrice += taxes
        }
    }
    
    static func createMockCart() -> PurchaseDomainsCart {
        .init(domains: [.init(name: "oleg.x", price: 100, metadata: nil)],
              totalPrice: 100,
              taxes: 0,
              storeCreditsAvailable: 100,
              promoCreditsAvailable: 2000,
              appliedDiscountDetails: .init(storeCredits: 100,
                                     promoCredits: 2000,
                                     others: 0))
    }
}
