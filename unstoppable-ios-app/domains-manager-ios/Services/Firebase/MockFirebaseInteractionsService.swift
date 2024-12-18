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
    var isApplePaySupported: Bool { false }

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
    func searchForDomains(key: String,
                          tlds: Set<String>) -> AsyncThrowingStream<[DomainToPurchase], Error> {
        AsyncThrowingStream { continuation in
            Task {
                await Task.sleep(seconds: 0.5)
                let key = key.lowercased()
                
                let domains = createDomainsWith(name: key)
                continuation.yield(domains)
                continuation.finish()
            }
        }
    }
    
    private func createDomainsWith(name: String) -> [DomainToPurchase] {
        let tlds: [String] = ["x", "crypto", "nft", "wallet", "polygon", "dao", "888", "blockchain", "go", "bitcoin"]
        let prices: [Int] = [Constants.maxPurchaseDomainsSum, 4000_00, 40000, 20000, 8000, 4000, 500]
        let isTaken: [Bool] = [true, false]
        let notSupportedTLDs: [String] = ["eth", "com"]
        
        let domains = tlds.map {
            DomainToPurchase(name: "\(name).\($0)",
                             price: prices.randomElement()!,
                             metadata: nil,
                             isTaken: isTaken.randomElement()!,
                             isAbleToPurchase: true)
        }
        let notSupportedDomains = notSupportedTLDs.map {
            DomainToPurchase(name: "\(name).\($0)",
                             price: prices.randomElement()!,
                             metadata: nil,
                             isTaken: isTaken.randomElement()!,
                             isAbleToPurchase: false)
        }
        
        return domains + notSupportedDomains
    }
    
    func aiSearchForDomains(hint: String) async throws -> [DomainToPurchase] {
        createDomainsWith(name: "ai_" + hint)
    }
    
    func getDomainsSuggestions(hint: String, tlds: Set<String>) async throws -> [DomainToPurchase] {
        await Task.sleep(seconds: 0.4)
        
        return createDomainsWith(name: "suggest_" + hint)
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
    
    func getPreferredWalletToMint() async throws -> PurchasedDomainsWalletDescription? {
        let userWallets = try await loadUserCryptoWallets()
        let wallet = userWallets[0]
        return PurchasedDomainsWalletDescription(address: wallet.address,
                                                 metadata: wallet.jsonData())
    }
    
    func purchaseDomainsInTheCartAndMintTo(wallet: PurchasedDomainsWalletDescription) async throws {
        
    }
    
    func refreshCart() async throws { }
    
    func authoriseWithWallet(_ wallet: UDWallet, toPurchaseDomains domains: [DomainToPurchase]) async throws {
        cart = MockFirebaseInteractionsService.createMockCart()
        updateCart()
    }
    
    func setDomainsToPurchase(_ domains: [DomainToPurchase]) async throws {
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
    
    func loadUserCryptoWallets() async throws -> [Ecom.UDUserAccountCryptWallet] {
        let wallets = MockEntitiesFabric.Wallet.mockEntities()
        var cryptoWallets: [Ecom.UDUserAccountCryptWallet] = []
        for (i, wallet) in wallets.enumerated() {
            let cryptoWallet = Ecom.UDUserAccountCryptWallet(id: i, address: wallet.address, type: "")
            cryptoWallets.append(cryptoWallet)
        }
        return cryptoWallets
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
        .init(domains: [.init(name: "oleg.x",
                              price: 10000,
                              metadata: nil,
                              isTaken: false,
                              isAbleToPurchase: true)],
              totalPrice: 10000,
              taxes: 0,
              storeCreditsAvailable: 100,
              promoCreditsAvailable: 2000,
              appliedDiscountDetails: .init(storeCredits: 100,
                                     promoCredits: 2000,
                                     others: 0))
    }
}
