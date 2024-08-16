//
//  EcomPurchaseInteractionService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation

class EcomPurchaseInteractionService: BaseFirebaseInteractionService {
    
    var udCart: Ecom.UDUserCart {
        didSet {
            didRefreshCart()
        }
    }
    var checkoutData: PurchaseDomainsCheckoutData
    var isAutoRefreshCartSuspended = false
    var cachedPaymentDetails: Ecom.StripePaymentDetails? = nil
    var isApplePaySupported: Bool { StripeService.isApplePaySupported }

    init(firebaseAuthService: FirebaseAuthService,
         firebaseSigner: UDFirebaseSigner,
         checkoutData: PurchaseDomainsCheckoutData) {
        udCart = .empty
        self.checkoutData = checkoutData
        super.init(firebaseAuthService: firebaseAuthService,
                   firebaseSigner: firebaseSigner)
    }
  
    func filterUnsupportedProductsFrom(products: [Ecom.UDProduct]) -> [Ecom.UDProduct] {
        products
    }
    
    func cartContainsUnsupportedProducts() { }
    
    func didRefreshCart() { }
    func loadUserProfile() async throws -> Ecom.UDUserProfileResponse {
        let urlString = URLSList.USER_PROFILE_URL
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: Ecom.UDUserProfileResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
}

// MARK: - Open methods
extension EcomPurchaseInteractionService {
    func loadUserCryptoWallets() async throws -> [Ecom.UDUserAccountCryptWallet] {
        let url = URLSList.CRYPTO_WALLETS_URL.appendingURLQueryComponents(["includeMinted" : String(true)])
        let request = try APIRequest(urlString: url, method: .get)
        let response: Ecom.UDUserAccountCryptWalletsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        
        return response.wallets
    }
}

// MARK: - Cart
extension EcomPurchaseInteractionService {
    func runRefreshTimer() {
        Task {
            if !isAutoRefreshCartSuspended {
                refreshUserCartAsync()
            }
            await Task.sleep(seconds: 60)
            runRefreshTimer()
        }
    }
    
    func makeCartOperationAPIRequestWith(urlString: String,
                                         products: [Ecom.UDProduct],
                                         shouldRefreshCart: Bool) async throws {
        let requestEntity = CartOperationRequestBody(products: products)
        let request = try APIRequest(urlString: urlString,
                                     body: requestEntity,
                                     method: .post)
        try await makeFirebaseAPIDataRequest(request)
        if shouldRefreshCart {
            try? await refreshUserCart()
        }
    }
    
    func loadUserCart() async throws -> Ecom.UserCartResponse {
        var queryComponents: [String : String] = [:]
        if !checkoutData.durationsMap.isEmpty {
            queryComponents["durationsMap"] = checkoutData.getDurationsMapString()
        }
        let urlString = URLSList.CART_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: Ecom.UserCartResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func refreshUserCartAsync() {
        Task {
            do {
                try await refreshUserCart()
            } catch {
                
            }
        }
    }
    
    func refreshUserCart(shouldFailIfCartContainsUnsupportedProducts: Bool = false) async throws {
        Debugger.printInfo("Will refresh cart")
        let cart = try await loadUserCart()
        try await removeCartUnsupportedProducts(in: cart.cart)
        
        async let cartResponseTask = loadUserCart()
        async let calculationsResponseTask = loadUserCartCalculations()
        async let userProfileResponseTask = loadUserProfile()
        
        let (cartResponse, calculationsResponse, userProfileResponse) = try await (cartResponseTask, calculationsResponseTask, userProfileResponseTask)
        
        
        if !filterUnsupportedProductsFrom(products: cartResponse.cart).isEmpty || !filterUnsupportedProductsFrom(products: calculationsResponse.cartItems).isEmpty  {
            if shouldFailIfCartContainsUnsupportedProducts {
                cartContainsUnsupportedProducts()
            } else {
                try await removeCartUnsupportedProducts(in: calculationsResponse.cartItems)
                try await refreshUserCart(shouldFailIfCartContainsUnsupportedProducts: true)
            }
            return
        }
        
        self.udCart = .init(products: cartResponse.cart,
                            calculations: calculationsResponse,
                            discountDetails: .init(storeCredits: userProfileResponse.storeCredits,
                                                   promoCredits: userProfileResponse.promoCredits))
        Debugger.printInfo("Did refresh cart")
    }
    
    func loadUserCartCalculations() async throws -> Ecom.UserCartCalculationsResponse {
        /// Always apply credits
        let queryComponents = ["applyPromoCredits" : String(true),
                               "applyStoreCredits" : String(true),
                               "discountCode" : checkoutData.discountCode.trimmedSpaces,
                               "durationsMap" : checkoutData.getDurationsMapString(),
                               "zipCode" : checkoutData.zipCodeIfEntered?.trimmedSpaces ?? ""]
        
        let urlString = URLSList.USER_CART_CALCULATIONS_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: Ecom.UserCartCalculationsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    private func removeCartUnsupportedProducts(in cart: [Ecom.UDProduct]) async throws {
        let productsToRemove = filterUnsupportedProductsFrom(products: cart)
        
        if !productsToRemove.isEmpty {
            try await removeProductsFromCart(productsToRemove, shouldRefreshCart: false)
        }
    }
    
    func addProductsToCart(_ products: [Ecom.UDProduct],
                           shouldRefreshCart: Bool) async throws {
        try await makeCartOperationAPIRequestWith(urlString: URLSList.CART_ADD_URL,
                                                  products: products,
                                                  shouldRefreshCart: shouldRefreshCart)
    }
    
    func removeProductsFromCart(_ products: [Ecom.UDProduct],
                                shouldRefreshCart: Bool) async throws {
        try await makeCartOperationAPIRequestWith(urlString: URLSList.CART_REMOVE_URL,
                                                  products: products,
                                                  shouldRefreshCart: shouldRefreshCart)
    }
    
}

// MARK: - Checkout
extension EcomPurchaseInteractionService {
    func purchaseProductsInTheCart(with cartDetails: Ecom.ProductsCartDetails?,
                                   totalAmountDue: Int) async throws {
        if totalAmountDue > 0 {
            try await purchaseProductsInTheCartWithStripe(with: cartDetails,
                                                          totalAmountDue: totalAmountDue)
        } else {
            try await purchaseProductsInTheCartWithCredits(with: cartDetails)
        }
    }
    
    private func purchaseProductsInTheCartWithStripe(with cartDetails: Ecom.ProductsCartDetails?,
                                                     totalAmountDue: Int) async throws {
        let paymentDetails = try await prepareStripePaymentDetails(with: cartDetails, amount: totalAmountDue)
        let paymentService = appContext.createStripeInstance(amount: paymentDetails.amount, using: paymentDetails.clientSecret)
        try await paymentService.payWithStripe()
        try? await refreshUserCart()
    }
    
    private func purchaseProductsInTheCartWithCredits(with cartDetails: Ecom.ProductsCartDetails?) async throws {
        try await checkoutWithCredits(with: cartDetails)
    }
    
    private func loadStripePaymentDetails(with cartDetails: Ecom.ProductsCartDetails?) async throws -> Ecom.StripePaymentDetailsResponse {
        struct RequestBody: Codable {
            let cryptoWalletId: Int?
            let email: String?
            var applyStoreCredits: Bool? = nil
            var applyPromoCredits: Bool? = nil
            let discountCode: String?
            let zipCode: String?
        }
        
        let urlString = URLSList.PAYMENT_STRIPE_URL
        let body = RequestBody(cryptoWalletId: cartDetails?.wallet?.id,
                               email: cartDetails?.email,
                               discountCode: checkoutData.discountCodeIfEntered,
                               zipCode: checkoutData.zipCodeIfEntered)
        let request = try APIRequest(urlString: urlString,
                                     body: body,
                                     method: .post)
        let response: Ecom.StripePaymentDetailsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    private func prepareStripePaymentDetails(with cartDetails: Ecom.ProductsCartDetails?,
                                             amount: Int) async throws -> Ecom.StripePaymentDetails {
        try await refreshUserCart()
        do {
            let detailsResponse = try await loadStripePaymentDetails(with: cartDetails)
            let details = Ecom.StripePaymentDetails(amount: amount,
                                                    clientSecret: detailsResponse.clientSecret,
                                                    orderId: detailsResponse.orderId)
            cachedPaymentDetails = details
            return details
        } catch {
            appContext.analyticsService.log(event: .purchaseGetPaymentDetailsError,
                                            withParameters: [.error: error.localizedDescription])
            if let cachedPaymentDetails {
                appContext.analyticsService.log(event: .purchaseWillUseCachedPaymentDetails, withParameters: nil)
                return cachedPaymentDetails
            }
            throw error
        }
    }
    
    private func checkoutWithCredits(with cartDetails: Ecom.ProductsCartDetails?) async throws {
        struct RequestBody: Codable {
            let cryptoWalletId: Int?
            var applyStoreCredits: Bool? = nil
            var applyPromoCredits: Bool? = nil
            let discountCode: String?
            let zipCode: String?
        }
        
        let urlString = URLSList.STORE_CHECKOUT_URL
        let body = RequestBody(cryptoWalletId: cartDetails?.wallet?.id,
                               discountCode: checkoutData.discountCodeIfEntered,
                               zipCode: checkoutData.zipCodeIfEntered)
        let request = try APIRequest(urlString: urlString,
                                     body: body,
                                     method: .post)
        try await makeFirebaseAPIDataRequest(request)
    }
    
}

// MARK: - Private methods
private extension EcomPurchaseInteractionService {
    struct CartOperationRequestBody: Codable {
        let products: [Ecom.UDProduct]
    }
}
