//
//  MockFirebaseInteractionService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.10.2023.
//

import UIKit
import Combine

final class MockFirebaseInteractionsService {
    
    @Published var firebaseUser: FirebaseUser?
    var authorizedUserPublisher: Published<FirebaseUser?>.Publisher { $firebaseUser }
    
    private var cart: PurchaseDomainsCart = .empty {
        didSet {
            cartStatus = .ready(cart: cart)
        }
    }
    @Published var cartStatus: PurchaseDomainCartStatus
    var cartStatusPublisher: Published<PurchaseDomainCartStatus>.Publisher { $cartStatus }
    var isApplePaySupported: Bool { true }

    @Published private(set) var parkedDomains: [FirebaseDomainDisplayInfo] = []
    var parkedDomainsPublisher: Published<[FirebaseDomainDisplayInfo]>.Publisher  { $parkedDomains }
    
    private var cancellables: Set<AnyCancellable> = []
    private var checkoutData: PurchaseDomainsCheckoutData
    
    init() {
        let preferencesService = PurchaseDomainsPreferencesStorage.shared
        checkoutData = preferencesService.checkoutData
        cartStatus = .ready(cart: cart)
        firebaseUser = .init(email: "qq@qq.qq")
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
    
    func logOut() {
        firebaseUser = nil
    }
}

// MARK: - PurchaseDomainsServiceProtocol
extension MockFirebaseInteractionsService: PurchaseDomainsServiceProtocol {
    func searchForDomains(key: String) async throws -> [DomainToPurchase] {
        await Task.sleep(seconds: 0.5)
        let key = key.lowercased()
        let tlds = ["x", "crypto", "nft", "wallet", "polygon", "dao", "888", "blockchain", "go", "bitcoin"]
        let prices = [40000, 20000, 8000, 4000, 500]
        let notSupportedTLDs = ["eth", "com"]
        
        let domains = tlds.map { DomainToPurchase(name: "\(key).\($0)", price: prices.randomElement()!, metadata: nil, isAbleToPurchase: true) }
        let notSupportedDomains = notSupportedTLDs.map { DomainToPurchase(name: "\(key).\($0)", price: prices.randomElement()!, metadata: nil, isAbleToPurchase: false) }
        
        return domains + notSupportedDomains
    }
    
    func aiSearchForDomains(hint: String) async throws -> [DomainToPurchase] {
        try await searchForDomains(key: "ai_" + hint)
    }
    
    func getDomainsSuggestions(hint: String?) async throws -> [DomainToPurchaseSuggestion] {
        await Task.sleep(seconds: 0.4)
        
        return ["greenfashion", "naturalstyle", "savvydressers", "ethicalclothes", "urbanfashions", "wearables", "consciouslook", "activegears", "minimalista", "outsizeoutfits", "styletone"].map { DomainToPurchaseSuggestion(name: $0) }
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
        cart = MockFirebaseInteractionsService.createMockCart()
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
        MockEntitiesFabric.Domains.mockFirebaseDomains()
    }
    func getParkedDomains() async throws -> [FirebaseDomain] {
        MockEntitiesFabric.Domains.mockFirebaseDomains()
    }
}

// MARK: - Private methods
private extension MockFirebaseInteractionsService {
    func authorize() async throws {
        await Task.sleep(seconds: 0.4)
        firebaseUser = .init(email: "qq@qq.qq")
    }
    
    func loadUserCryptoWallets() async throws -> [FirebasePurchaseDomainsService.UDUserAccountCryptWallet] {
        let wallets = appContext.udWalletsService.getUserWallets()
        return wallets.map { FirebasePurchaseDomainsService.UDUserAccountCryptWallet(id: 1, address: $0.address) }
//        [.init(id: 1605, address: "0xc4a748796805dfa42cafe0901ec182936584cc6e"),
//         .init(id: 1606, address: "0x8ed92xjd2793yenx837g3847d3n4dx9h")]
    }
    
    func updateCart() {
        var cart = self.cart
        cart.totalPrice = cart.domains.reduce(0, { $0 + $1.price })
        let storeCredits = checkoutData.isStoreCreditsOn ? 100 : 0
        let promoCredits = checkoutData.isPromoCreditsOn ? 2000 : 0
        let otherDiscounts = checkoutData.discountCode.isEmpty ? 0 : cart.totalPrice / 3
        cart.appliedDiscountDetails = .init(storeCredits: storeCredits, 
                                            promoCredits: promoCredits,
                                            others: otherDiscounts)
        cart.totalPrice -= (storeCredits + promoCredits + otherDiscounts)
        if !checkoutData.usaZipCode.isEmpty {
            let taxes = 200
            cart.taxes = taxes
            cart.totalPrice += taxes
        }
        self.cart = cart
    }
    
    static func createMockCart() -> PurchaseDomainsCart {
        .init(domains: [.init(name: "oleg.x", price: 10000, metadata: nil, isAbleToPurchase: true)],
              totalPrice: 10000,
              taxes: 0,
              storeCreditsAvailable: 100,
              promoCreditsAvailable: 2000,
              appliedDiscountDetails: .init(storeCredits: 100,
                                     promoCredits: 2000,
                                     others: 0))
    }
}
