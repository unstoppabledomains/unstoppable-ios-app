//
//  FirebasePurchaseMPCWalletService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation
import Combine

final class EcomPurchaseMPCWalletService: EcomPurchaseInteractionService {
    
    @Published var cartStatus: PurchaseMPCWalletCartStatus
    var cartStatusPublisher: Published<PurchaseMPCWalletCartStatus>.Publisher { $cartStatus }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(firebaseAuthService: FirebaseAuthService,
         firebaseSigner: UDFirebaseSigner,
         preferencesService: PurchaseDomainsPreferencesStorage) {
        cartStatus = .ready(cart: .empty)
        super.init(firebaseAuthService: firebaseAuthService,
                   firebaseSigner: firebaseSigner,
                   checkoutData: preferencesService.checkoutData)
        preferencesService.$checkoutData.publisher
            .sink { [weak self] checkoutData in
                self?.checkoutData = checkoutData
                self?.refreshUserCartAsync()
            }
            .store(in: &cancellables)
    }
    private var shouldCheckForRequestError: Bool {
        !isAutoRefreshCartSuspended
    }
    
    @discardableResult
    override func makeFirebaseAPIDataRequest(_ apiRequest: APIRequest) async throws -> Data {
        do {
            return try await super.makeFirebaseAPIDataRequest(apiRequest)
        } catch {
            appContext.analyticsService.log(event: .purchaseFirebaseRequestError,
                                            withParameters: [.error: error.localizedDescription,
                                                             .value: apiRequest.url.absoluteString])
            if shouldCheckForRequestError {
                cartStatus = .failedToLoadCalculations { self.refreshUserCartAsync() }
            }
            throw error
        }
    }
    
    override func makeFirebaseDecodableAPIDataRequest<T>(_ apiRequest: APIRequest,
                                                         using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                         dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T where T : Decodable {
        do {
            return try await super.makeFirebaseDecodableAPIDataRequest(apiRequest,
                                                                       using: keyDecodingStrategy,
                                                                       dateDecodingStrategy: dateDecodingStrategy)
        } catch {
            appContext.analyticsService.log(event: .purchaseFirebaseRequestError,
                                            withParameters: [.error: error.localizedDescription,
                                                             .value: apiRequest.url.absoluteString])
            if shouldCheckForRequestError {
                cartStatus = .failedToLoadCalculations { self.refreshUserCartAsync() }
            }
            throw error
        }
    }
    
    override func filterUnsupportedProductsFrom(products: [Ecom.UDProduct]) -> [Ecom.UDProduct] {
        products.filter( {
            if case .mpcWallet = $0 {
                return false
            }
            return true
        })
    }
    
    override func cartContainsUnsupportedProducts() {
        cartStatus = .alreadyPurchasedMPCWallet
//        appContext.analyticsService.log(event: .accountHasUnpaidDomains, withParameters: nil)
    }
    
    override func didRefreshCart() {
        cartStatus = .ready(cart: createCartFromUDCart(udCart))
    }
}

// MARK: - EcomPurchaseMPCWalletServiceProtocol
extension EcomPurchaseMPCWalletService: EcomPurchaseMPCWalletServiceProtocol {
    func authoriseWithEmail(_ email: String, password: String) async throws {
        await prepareBeforeAuth()
        try await firebaseAuthService.authorizeWith(email: email, password: password)
        try await didAuthorise()
    }
    
    func authoriseWithGoogle() async throws {
        guard let window = await SceneDelegate.shared?.window else { throw PurchaseMPCWalletError.failedToAuthorise }

        await prepareBeforeAuth()
        try await firebaseAuthService.authorizeWithGoogleSignInIdToken(in: window)
        try await didAuthorise()
    }
    
    func authoriseWithTwitter() async throws {
        guard let topVC = await appContext.coreAppCoordinator.topVC else { throw PurchaseMPCWalletError.failedToAuthorise }
        
        await prepareBeforeAuth()
        try await firebaseAuthService.authorizeWithTwitterCustomToken(in: topVC)
        try await didAuthorise()
    }
    
    func authoriseWithWallet(_ wallet: UDWallet) async throws {
        await prepareBeforeAuth()
        try await firebaseAuthService.authorizeWith(wallet: wallet)
        try await didAuthorise()
    }
   
    func reset() async {
        cartStatus = .ready(cart: .empty)
        cachedPaymentDetails = nil
        await logout()
    }
    
    func refreshCart() async throws {
        try await refreshUserCart()
    }
    
    func purchaseMPCWallet() async throws {
        isAutoRefreshCartSuspended = true
        try await purchaseProductsInTheCart(to: nil,
                                            totalAmountDue: udCart.calculations.totalAmountDue)
        isAutoRefreshCartSuspended = false
    }
}

// MARK: - Cart
private extension EcomPurchaseMPCWalletService {
    func prepareBeforeAuth() async {
        await reset()
    }
    
    func didAuthorise() async throws {
        let isAlreadyPurchasedMPCWallet = try await isAlreadyPurchasedMPCWallet()
        if isAlreadyPurchasedMPCWallet {
            self.cartStatus = .alreadyPurchasedMPCWallet
        } else {
            try await addProductsToCart([.mpcWallet(.init())], shouldRefreshCart: true)
        }
        
        isAutoRefreshCartSuspended = false
    }
    
    func isAlreadyPurchasedMPCWallet() async throws -> Bool {
        let wallets = try await loadUserCryptoWallets()
        if wallets.first(where: { $0.type == "EvmPlatformMpcWallet" }) != nil {
            return true
        }
        return false
    }
    
    func createCartFromUDCart(_ udCart: Ecom.UDUserCart) -> PurchaseMPCWalletCart {
        let otherDiscountsSum = udCart.calculations.discounts.reduce(0, { $0 + $1.amount })
        return PurchaseMPCWalletCart(totalPrice: udCart.calculations.totalAmountDue,
                                     taxes: udCart.calculations.salesTax,
                                     storeCreditsAvailable: udCart.discountDetails.storeCredits,
                                     promoCreditsAvailable: udCart.discountDetails.promoCredits,
                                     appliedDiscountDetails: .init(storeCredits: udCart.calculations.storeCreditsUsed,
                                                                   promoCredits: udCart.calculations.promoCreditsUsed,
                                                                   others: otherDiscountsSum))
    }
    
    enum PurchaseMPCWalletError: String, LocalizedError {
        case failedToAuthorise
        case udAccountHasUnpaidVault
    }
}
