//
//  FirebasePurchaseMPCWalletService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation
import Combine

final class FirebasePurchaseMPCWalletService: EcomPurchaseInteractionService {
    
    @Published var cartStatus: PurchaseMPCWalletCartStatus
    var cartStatusPublisher: Published<PurchaseMPCWalletCartStatus>.Publisher { $cartStatus }
    
    private let queue = DispatchQueue(label: "com.unstoppabledomains.firebase.purchase.mpc.service")
    private var cancellables: Set<AnyCancellable> = []
    var isApplePaySupported: Bool { StripeService.isApplePaySupported }
    
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
    
    override func cartContainsUnsupportedProducts() {
        cartStatus = .alreadyPurchasedMPCWallet
//        appContext.analyticsService.log(event: .accountHasUnpaidDomains, withParameters: nil)
    }
    
    override func didRefreshCart() {
        cartStatus = .ready(cart: createCartFromUDCart(udCart))
    }
}

// MARK: - PurchaseDomainsServiceProtocol
extension FirebasePurchaseMPCWalletService {
    func addDomainsToCart(_ domains: [DomainToPurchase]) async throws {
        let domainItems = domains.compactMap({ $0.metadata }).compactMap({ Ecom.DomainProductItem.objectFromData($0) })
        let products = domainItems.map { Ecom.UDProduct.domain($0) }
        try await addProductsToCart(products, shouldRefreshCart: true)
    }
    
    func removeDomainsFromCart(_ domains: [DomainToPurchase]) async throws {
        let domainItems = domains.compactMap({ $0.metadata }).compactMap({ Ecom.DomainProductItem.objectFromData($0) })
        let products = domainItems.map { Ecom.UDProduct.domain($0) }
        try await removeProductsFromCart(products, shouldRefreshCart: true)
    }
    
    func authoriseWithWallet(_ wallet: UDWallet) async throws {
        await reset()
        do {
            try await firebaseAuthService.authorizeWith(wallet: wallet)
        } catch {
            throw error
        }
        try await addDomainsToCart([])
        isAutoRefreshCartSuspended = false
    }
    
    func reset() async {
        cartStatus = .ready(cart: .empty)
        cachedPaymentDetails = nil
        await logout()
    }
    
    func getSupportedWalletsToMint() async throws -> [PurchasedDomainsWalletDescription] {
        let userWallets = try await loadUserCryptoWallets()
        return userWallets.map { PurchasedDomainsWalletDescription(address: $0.address, metadata: $0.jsonData()) }
    }
    
    func refreshCart() async throws {
        try await refreshUserCart()
    }
    
    func purchaseDomainsInTheCartAndMintTo(wallet: PurchasedDomainsWalletDescription) async throws {
        isAutoRefreshCartSuspended = true
        let userWallet = try Ecom.UDUserAccountCryptWallet.objectFromDataThrowing(wallet.metadata ?? Data())
        try await purchaseProductsInTheCart(to: userWallet,
                                            totalAmountDue: udCart.calculations.totalAmountDue)
        isAutoRefreshCartSuspended = false
    }
}

// MARK: - Cart
private extension FirebasePurchaseMPCWalletService {
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
    
    enum PurchaseDomainsError: String, LocalizedError {
        case udAccountHasUnpaidVault
    }
}
