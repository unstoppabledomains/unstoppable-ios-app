//
//  FirebasePurchaseMPCWalletService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation
import Combine

enum PurchaseMPCWalletCartStatus {
    case alreadyPurchasedMPCWallet
    case failedToLoadCalculations(MainActorAsyncCallback)
    case ready(cart: PurchaseMPCWalletCart)
    
    var promoCreditsAvailable: Int {
        switch self {
        case .ready(let cart):
            return cart.promoCreditsAvailable
        default:
            return 0
        }
    }
    var storeCreditsAvailable: Int {
        switch self {
        case .ready(let cart):
            return cart.storeCreditsAvailable
        default:
            return 0
        }
    }
    var otherDiscountsApplied: Int {
        switch self {
        case .ready(let cart):
            return cart.appliedDiscountDetails.others
        default:
            return 0
        }
    }
    var discountsAppliedSum: Int {
        switch self {
        case .ready(let cart):
            return cart.appliedDiscountDetails.totalSum
        default:
            return 0
        }
    }
    var taxes: Int {
        switch self {
        case .ready(let cart):
            return cart.taxes
        default:
            return 0
        }
    }
    var totalPrice: Int {
        switch self {
        case .ready(let cart):
            return cart.totalPrice
        default:
            return 0
        }
    }
}


struct PurchaseMPCWalletCart {
    
    static let empty = PurchaseMPCWalletCart(totalPrice: 0,
                                             taxes: 0,
                                             storeCreditsAvailable: 0,
                                             promoCreditsAvailable: 0,
                                             appliedDiscountDetails: .init(storeCredits: 0,
                                                                           promoCredits: 0,
                                                                           others: 0))
    
    var totalPrice: Int
    var taxes: Int
    let storeCreditsAvailable: Int
    let promoCreditsAvailable: Int
    var appliedDiscountDetails: AppliedDiscountDetails
    
    struct AppliedDiscountDetails {
        let storeCredits: Int
        let promoCredits: Int
        var others: Int
        
        var totalSum: Int { storeCredits + promoCredits + others }
    }
}



final class FirebasePurchaseMPCWalletService: BaseFirebaseInteractionService {
    
    @Published var cartStatus: PurchaseMPCWalletCartStatus
    var cartStatusPublisher: Published<PurchaseMPCWalletCartStatus>.Publisher { $cartStatus }
    
    private var udCart: FirebasePurchase.UDUserCart {
        didSet {
            cartStatus = .ready(cart: createCartFromUDCart(udCart))
        }
    }
    
    private let queue = DispatchQueue(label: "com.unstoppabledomains.firebase.purchase.mpc.service")
    private var cancellables: Set<AnyCancellable> = []
    private var checkoutData: PurchaseDomainsCheckoutData
    private var cachedPaymentDetails: FirebasePurchase.StripePaymentDetails? = nil
    private var isAutoRefreshCartSuspended = false
    var isApplePaySupported: Bool { StripeService.isApplePaySupported }
    
    init(firebaseAuthService: FirebaseAuthService,
         firebaseSigner: UDFirebaseSigner,
         preferencesService: PurchaseDomainsPreferencesStorage) {
        udCart = .empty
        cartStatus = .ready(cart: .empty)
        checkoutData = preferencesService.checkoutData
        super.init(firebaseAuthService: firebaseAuthService,
                   firebaseSigner: firebaseSigner)
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
}

// MARK: - PurchaseDomainsServiceProtocol
extension FirebasePurchaseMPCWalletService {
    func addDomainsToCart(_ domains: [DomainToPurchase]) async throws {
        let domainItems = domains.compactMap({ $0.metadata }).compactMap({ FirebasePurchase.DomainProductItem.objectFromData($0) })
        let products = domainItems.map { FirebasePurchase.UDProduct.domain($0) }
        try await addProductsToCart(products, shouldRefreshCart: true)
    }
    
    func removeDomainsFromCart(_ domains: [DomainToPurchase]) async throws {
        let domainItems = domains.compactMap({ $0.metadata }).compactMap({ FirebasePurchase.DomainProductItem.objectFromData($0) })
        let products = domainItems.map { FirebasePurchase.UDProduct.domain($0) }
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
        let userWallet = try FirebasePurchase.UDUserAccountCryptWallet.objectFromDataThrowing(wallet.metadata ?? Data())
        try await purchaseDomainsInTheCart(to: userWallet)
        isAutoRefreshCartSuspended = false
    }
}

// MARK: - Private methods
private extension FirebasePurchaseMPCWalletService {
    func addProductsToCart(_ products: [FirebasePurchase.UDProduct],
                           shouldRefreshCart: Bool) async throws {
        try await makeCartOperationAPIRequestWith(urlString: URLSList.CART_ADD_URL,
                                                  products: products,
                                                  shouldRefreshCart: shouldRefreshCart)
    }
    
    func removeProductsFromCart(_ products: [FirebasePurchase.UDProduct],
                                shouldRefreshCart: Bool) async throws {
        try await makeCartOperationAPIRequestWith(urlString: URLSList.CART_REMOVE_URL,
                                                  products: products,
                                                  shouldRefreshCart: shouldRefreshCart)
    }
    
    func purchaseDomainsInTheCart(to wallet: FirebasePurchase.UDUserAccountCryptWallet) async throws {
        if udCart.calculations.totalAmountDue > 0 {
            try await purchaseDomainsInTheCartWithStripe(to: wallet)
        } else {
            try await purchaseDomainsInTheCartWithCredits(to: wallet)
        }
    }
    
    func purchaseDomainsInTheCartWithStripe(to wallet: FirebasePurchase.UDUserAccountCryptWallet) async throws {
        let paymentDetails = try await prepareStripePaymentDetails(for: wallet)
        let paymentService = appContext.createStripeInstance(amount: paymentDetails.amount, using: paymentDetails.clientSecret)
        try await paymentService.payWithStripe()
        try? await refreshUserCart()
    }
    
    func purchaseDomainsInTheCartWithCredits(to wallet: FirebasePurchase.UDUserAccountCryptWallet) async throws {
        try await checkoutWithCredits(to: wallet)
    }
    
    func loadUserCryptoWallets() async throws -> [FirebasePurchase.UDUserAccountCryptWallet] {
        let url = URLSList.CRYPTO_WALLETS_URL.appendingURLQueryComponents(["includeMinted" : String(true)])
        let request = try APIRequest(urlString: url, method: .get)
        let response: FirebasePurchase.UDUserAccountCryptWalletsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        
        return response.wallets
    }
    
    func transformDomainProductItemsToDomainsToPurchase(_ productItems: [FirebasePurchase.DomainProductItem]) -> [DomainToPurchase] {
        []
    }
}

// MARK: - Cart
private extension FirebasePurchaseMPCWalletService {
    struct CartOperationRequestBody: Codable {
        let products: [FirebasePurchase.UDProduct]
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
//                cartStatus = .hasUnpaidDomains
                appContext.analyticsService.log(event: .accountHasUnpaidDomains, withParameters: nil)
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
    
    func runRefreshTimer() {
        Task {
            if !isAutoRefreshCartSuspended {
                refreshUserCartAsync()
            }
            await Task.sleep(seconds: 60)
            runRefreshTimer()
        }
    }
    
    func loadUserProfile() async throws -> FirebasePurchase.UDUserProfileResponse {
        let urlString = URLSList.USER_PROFILE_URL
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: FirebasePurchase.UDUserProfileResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func loadUserCart() async throws -> FirebasePurchase.UserCartResponse {
        var queryComponents: [String : String] = [:]
        if !checkoutData.durationsMap.isEmpty {
            queryComponents["durationsMap"] = checkoutData.getDurationsMapString()
        }
        let urlString = URLSList.CART_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: FirebasePurchase.UserCartResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func createCartFromUDCart(_ udCart: FirebasePurchase.UDUserCart) -> PurchaseMPCWalletCart {
        let otherDiscountsSum = udCart.calculations.discounts.reduce(0, { $0 + $1.amount })
        return PurchaseMPCWalletCart(totalPrice: udCart.calculations.totalAmountDue,
                                     taxes: udCart.calculations.salesTax,
                                     storeCreditsAvailable: udCart.discountDetails.storeCredits,
                                     promoCreditsAvailable: udCart.discountDetails.promoCredits,
                                     appliedDiscountDetails: .init(storeCredits: udCart.calculations.storeCreditsUsed,
                                                                   promoCredits: udCart.calculations.promoCreditsUsed,
                                                                   others: otherDiscountsSum))
    }
    
    func makeCartOperationAPIRequestWith(urlString: String,
                                         products: [FirebasePurchase.UDProduct],
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
    
    func checkoutWithCredits(to wallet: FirebasePurchase.UDUserAccountCryptWallet) async throws {
        struct RequestBody: Codable {
            let cryptoWalletId: Int
            let applyStoreCredits: Bool
            let applyPromoCredits: Bool
            let discountCode: String?
            let zipCode: String?
        }
        
        let urlString = URLSList.STORE_CHECKOUT_URL
        let body = RequestBody(cryptoWalletId: wallet.id,
                               applyStoreCredits: checkoutData.isStoreCreditsOn,
                               applyPromoCredits: checkoutData.isPromoCreditsOn,
                               discountCode: checkoutData.discountCodeIfEntered,
                               zipCode: checkoutData.zipCodeIfEntered)
        let request = try APIRequest(urlString: urlString,
                                     body: body,
                                     method: .post)
        try await makeFirebaseAPIDataRequest(request)
    }
    
    func loadStripePaymentDetails(for wallet: FirebasePurchase.UDUserAccountCryptWallet) async throws -> FirebasePurchase.StripePaymentDetailsResponse {
        struct RequestBody: Codable {
            let cryptoWalletId: Int
            let applyStoreCredits: Bool
            let applyPromoCredits: Bool
            let discountCode: String?
            let zipCode: String?
        }
        
        let urlString = URLSList.PAYMENT_STRIPE_URL
        let body = RequestBody(cryptoWalletId: wallet.id,
                               applyStoreCredits: checkoutData.isStoreCreditsOn,
                               applyPromoCredits: checkoutData.isPromoCreditsOn,
                               discountCode: checkoutData.discountCodeIfEntered,
                               zipCode: checkoutData.zipCodeIfEntered)
        let request = try APIRequest(urlString: urlString,
                                     body: body,
                                     method: .post)
        let response: FirebasePurchase.StripePaymentDetailsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func prepareStripePaymentDetails(for wallet: FirebasePurchase.UDUserAccountCryptWallet) async throws -> FirebasePurchase.StripePaymentDetails {
        try await refreshUserCart()
        do {
            let detailsResponse = try await loadStripePaymentDetails(for: wallet)
            let details = FirebasePurchase.StripePaymentDetails(amount: udCart.calculations.totalAmountDue,
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
    
    func loadCartParkingProducts(in cart: FirebasePurchase.UDUserCart) async {
        var cart = cart
        var products = cart.products
        
        await withTaskGroup(of: FirebasePurchase.UDProduct.self) { group in
            for product in products {
                group.addTask {
                    switch product {
                    case .domain(var domain):
                        var availableProducts = domain.availableProducts ?? []
                        
                        // Check for ENS registry fee
                        if domain.isENSDomain {
                            if !domain.isENSRenewalAdded {
                                availableProducts.append(.ensAutoRenewal(.createENSRenewableProductDetails(for: domain.domain)))
                            }
                        }
                        
                        // Check for available parking option
                        if !domain.hasUDVEnabled,
                           let parkingProduct = try? await self.loadDomainParkingProductCart(for: domain.domain) {
                            availableProducts.append(parkingProduct)
                        }
                        domain.availableProducts = availableProducts
                        
                        return .domain(domain)
                    case .parking, .ensAutoRenewal, .unknown:
                        return product
                    }
                }
            }
            
            for await product in group {
                if let i = products.firstIndex(where: { $0.id == product.id }) {
                    products[i] = product
                }
            }
        }
        
        cart.products = products
        self.udCart = cart
    }
    
    func removeCartUnsupportedProducts(in cart: [FirebasePurchase.UDProduct]) async throws {
        let productsToRemove = filterUnsupportedProductsFrom(products: cart)
        
        if !productsToRemove.isEmpty {
            try await removeProductsFromCart(productsToRemove, shouldRefreshCart: false)
        }
    }
    
    func filterUnsupportedProductsFrom(products: [FirebasePurchase.UDProduct]) -> [FirebasePurchase.UDProduct] {
        products.flatMap { product -> [FirebasePurchase.UDProduct] in
            switch product {
            case .domain(let domain):
                /// Remove all domains except what user has selected for purchase
             
                return domain.hiddenProducts
            default:
                return [product]
            }
        }
    }
    
    func loadDomainParkingProductCart(for domain: FirebasePurchase.DomainProductDetails) async throws -> FirebasePurchase.UDProduct {
        let urlString = URLSList.DOMAINS_PARKING_PRODUCT_URL(domain: domain.name)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        return try await makeFirebaseDecodableAPIDataRequest(request)
    }
    
    func loadUserCartCalculations() async throws -> FirebasePurchase.UserCartCalculationsResponse {
        let queryComponents = ["applyPromoCredits" : String(checkoutData.isPromoCreditsOn),
                               "applyStoreCredits" : String(checkoutData.isStoreCreditsOn),
                               "discountCode" : checkoutData.discountCode.trimmedSpaces,
                               "durationsMap" : checkoutData.getDurationsMapString(),
                               "zipCode" : checkoutData.usaZipCode.trimmedSpaces]
        
        let urlString = URLSList.USER_CART_CALCULATIONS_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: FirebasePurchase.UserCartCalculationsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    enum PurchaseDomainsError: String, LocalizedError {
        case udAccountHasUnpaidVault
    }
}
