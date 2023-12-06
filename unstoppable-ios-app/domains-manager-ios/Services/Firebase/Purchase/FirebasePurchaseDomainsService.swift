//
//  FirebasePurchaseDomainsService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 31.10.2023.
//

import Foundation
import Combine

private extension BaseFirebaseInteractionService.URLSList {
    static var USER_URL: String { baseAPIURL.appendingURLPathComponent("user") }
    static var USER_PROFILE_URL: String { USER_URL.appendingURLPathComponent("profile") }
    
    static var DOMAIN_URL: String { baseAPIURL.appendingURLPathComponent("domain") }
    static var DOMAIN_SEARCH_URL: String { DOMAIN_URL.appendingURLPathComponent("search") }
    static var DOMAIN_AI_SUGGESTIONS_URL: String { DOMAIN_SEARCH_URL.appendingURLPathComponent("ai-suggestions") }
    static func DOMAIN_ENS_STATUS_URL(domain: String) -> String {
        DOMAIN_URL.appendingURLPathComponents(domain, "ens-status")
    }
    
    static var DOMAINS_URL: String { baseAPIURL.appendingURLPathComponent("domains") }
    static func DOMAINS_PARKING_PRODUCT_URL(domain: String) -> String {
        DOMAINS_URL.appendingURLPathComponents(domain, "parking-product")
    }
    
    static var CART_URL: String { baseAPIURL.appendingURLPathComponent("cart") }
    static var CART_ADD_URL: String { CART_URL.appendingURLPathComponent("add") }
    static var CART_REMOVE_URL: String { CART_URL.appendingURLPathComponent("remove") }
    
    static var USER_CART_URL: String { USER_URL.appendingURLPathComponent("cart") }
    static var USER_CART_CALCULATIONS_URL: String { USER_CART_URL.appendingURLPathComponent("calculations") }
    
    static var PAYMENT_STRIPE_URL: String { baseAPIURL.appendingURLPathComponents("payment", "stripe") }
    static var CRYPTO_WALLETS_URL: String { baseAPIURL.appendingURLPathComponent("crypto-wallets") }

}

final class FirebasePurchaseDomainsService: BaseFirebaseInteractionService {
    
    @Published var cartStatus: PurchaseDomainCartStatus
    var cartStatusPublisher: Published<PurchaseDomainCartStatus>.Publisher { $cartStatus }

    private var udCart: UDUserCart {
        didSet {
            cartStatus = .ready(cart: createCartFromUDCart(udCart))
        }
    }

    private let queue = DispatchQueue(label: "com.unstoppabledomains.firebase.purchase.service")
    private var cancellables: Set<AnyCancellable> = []
    private var checkoutData: PurchaseDomainsCheckoutData
    private var cachedPaymentDetails: StripePaymentDetails? = nil
    private var isAutoRefreshCartSuspended = false
    private var domainsToPurchase: [DomainToPurchase] = []

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
        !isAutoRefreshCartSuspended && !domainsToPurchase.isEmpty
    }
 
    @discardableResult
    override func makeFirebaseAPIDataRequest(_ apiRequest: APIRequest) async throws -> Data {
        do {
            return try await super.makeFirebaseAPIDataRequest(apiRequest)
        } catch {
            if shouldCheckForRequestError {
                cartStatus = .failedToLoadCalculations(refreshUserCartAsync)
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
            if shouldCheckForRequestError {
                cartStatus = .failedToLoadCalculations(refreshUserCartAsync)
            }
            throw error
        }
    }
}

// MARK: - PurchaseDomainsServiceProtocol
extension FirebasePurchaseDomainsService: PurchaseDomainsServiceProtocol {
    func searchForDomains(key: String) async throws -> [DomainToPurchase] {
        let searchResult = try await self.searchForFBDomains(key: key)
        let domains = searchResult.exact
            .filter({ $0.availability })
            .map { DomainToPurchase(domainProduct: $0) }
        return domains
    }
    
    func getDomainsSuggestions(hint: String?) async throws -> [DomainToPurchaseSuggestion] {
        let hint = hint ?? "Anything you think is trending now"
        let queryComponents = ["phrase" : hint,
                               "extension" : "All"]
        let urlString = URLSList.DOMAIN_AI_SUGGESTIONS_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: SuggestDomainsResponse = try await NetworkService().makeDecodableAPIRequest(request)
        return response.suggestions.map { DomainToPurchaseSuggestion(name: $0.domain.label) }
    }
    
    func addDomainsToCart(_ domains: [DomainToPurchase]) async throws {
        let domainItems = domains.compactMap({ $0.metadata }).compactMap({ DomainProductItem.objectFromData($0) })
        let products = domainItems.map { UDProduct.domain($0) }
        try await addProductsToCart(products, shouldRefreshCart: true)
    }
    
    func removeDomainsFromCart(_ domains: [DomainToPurchase]) async throws {
        let domainItems = domains.compactMap({ $0.metadata }).compactMap({ DomainProductItem.objectFromData($0) })
        let products = domainItems.map { UDProduct.domain($0) }
        try await removeProductsFromCart(products, shouldRefreshCart: true)
    }
    
    func authoriseWithWallet(_ wallet: UDWallet, toPurchaseDomains domains: [DomainToPurchase]) async throws {
        await reset()
        do {
            try await firebaseAuthService.authorizeWith(wallet: wallet)
        } catch {
            cartStatus = .failedToAuthoriseWallet(wallet)
            throw error
        }
        self.domainsToPurchase = domains
        try await addDomainsToCart(domains)
        isAutoRefreshCartSuspended = false
    }
    
    func reset() async {
        cartStatus = .ready(cart: .empty)
        self.domainsToPurchase = []
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
        try await refreshUserCart()
        let userWallet = try UDUserAccountCryptWallet.objectFromDataThrowing(wallet.metadata ?? Data())
        try await purchaseDomainsInTheCart(to: userWallet)
        isAutoRefreshCartSuspended = false
    }
}

// MARK: - Private methods
private extension FirebasePurchaseDomainsService {
    func searchForFBDomains(key: String) async throws -> SearchDomainsResponse {
        var searchResponse = try await makeSearchDomainsRequestWith(key: key)
        searchResponse.exact = searchResponse.exact.filter({ !$0.isENSDomain })
        return searchResponse
    }
    
    func addProductsToCart(_ products: [UDProduct],
                           shouldRefreshCart: Bool) async throws {
        try await makeCartOperationAPIRequestWith(urlString: URLSList.CART_ADD_URL,
                                                  products: products,
                                                  shouldRefreshCart: shouldRefreshCart)
    }
    
    func removeProductsFromCart(_ products: [UDProduct],
                                shouldRefreshCart: Bool) async throws {
        try await makeCartOperationAPIRequestWith(urlString: URLSList.CART_REMOVE_URL,
                                                  products: products,
                                                  shouldRefreshCart: shouldRefreshCart)
    }
    
    func purchaseDomainsInTheCart(to wallet: UDUserAccountCryptWallet) async throws {
        let paymentDetails = try await prepareStripePaymentDetails(for: wallet)
        let paymentService = appContext.createStripeInstance(amount: paymentDetails.amount, using: paymentDetails.clientSecret)
        try await paymentService.payWithStripe()
        try? await refreshUserCart()
    }
    func makeSearchDomainsRequestWith(key: String) async throws -> SearchDomainsResponse {
        let queryComponents = ["q" : key]
        let urlString = URLSList.DOMAIN_SEARCH_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: SearchDomainsResponse = try await NetworkService().makeDecodableAPIRequest(request)
        return response
    }
    
    func getENSDomainStatus(domainName: String) async throws -> ENSDomainProductStatusResponse {
        let urlString = URLSList.DOMAIN_ENS_STATUS_URL(domain: domainName)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let status: ENSDomainProductStatusResponse = try await makeFirebaseDecodableAPIDataRequest(request,
                                                                                                   dateDecodingStrategy: .defaultDateDecodingStrategy())
        return status
    }
    
    func loadUserCryptoWallets() async throws -> [UDUserAccountCryptWallet] {
        let url = URLSList.CRYPTO_WALLETS_URL.appendingURLQueryComponents(["includeMinted" : String(true)])
        let request = try APIRequest(urlString: url, method: .get)
        let response: UDUserAccountCryptWalletsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        
        return response.wallets
    }
}

// MARK: - Cart
private extension FirebasePurchaseDomainsService {
    struct CartOperationRequestBody: Codable {
        let products: [UDProduct]
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
                cartStatus = .hasUnpaidDomains
                appContext.analyticsService.log(event: .accountHasUnpaidDomains, withParameters: nil)
            } else {
                try await removeCartUnsupportedProducts(in: calculationsResponse.cartItems)
                try await refreshUserCart(shouldFailIfCartContainsUnsupportedProducts: true)
            }
            return
        }
        
        self.udCart = UDUserCart(products: cartResponse.cart,
                                 calculations: calculationsResponse,
                                 discountDetails: .init(storeCredits: userProfileResponse.storeCredits,
                                                        promoCredits: userProfileResponse.promoCredits))
        Debugger.printInfo("Did refresh cart")
    }
    
    func runRefreshTimer() {
        Task {
            do {
                if !isAutoRefreshCartSuspended,
                   !domainsToPurchase.isEmpty {
                    refreshUserCartAsync()
                }
                try await Task.sleep(seconds: 60)
                runRefreshTimer()
            } catch {
                
            }
        }
    }
    
    func loadUserProfile() async throws -> UDUserProfileResponse {
        let urlString = URLSList.USER_PROFILE_URL
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: UDUserProfileResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func loadUserCart() async throws -> UserCartResponse {
        var queryComponents: [String : String] = [:]
        if !checkoutData.durationsMap.isEmpty {
            queryComponents["durationsMap"] = checkoutData.getDurationsMapString()
        }
        let urlString = URLSList.CART_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: UserCartResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func createCartFromUDCart(_ udCart: UDUserCart) -> PurchaseDomainsCart {
        let domainProducts = udCart.products.compactMap { product in
            switch product {
            case .domain(let domainProductItem):
                return domainProductItem
            case .parking, .ensAutoRenewal:
                return nil
            }
        }
        let domains = domainProducts.map { DomainToPurchase(domainProduct: $0) }
        let otherDiscountsSum = udCart.calculations.discounts.reduce(0, { $0 + $1.amount })
        return PurchaseDomainsCart(domains: domains,
                                   totalPrice: udCart.calculations.totalAmountDue,
                                   taxes: udCart.calculations.salesTax,
                                   storeCreditsAvailable: udCart.discountDetails.storeCredits,
                                   promoCreditsAvailable: udCart.discountDetails.promoCredits,
                                   appliedDiscountDetails: .init(storeCredits: udCart.calculations.storeCreditsUsed,
                                                          promoCredits: udCart.calculations.promoCreditsUsed,
                                                          others: otherDiscountsSum))
    }
    
    func makeCartOperationAPIRequestWith(urlString: String,
                                         products: [UDProduct],
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
    
    func loadStripePaymentDetails(for wallet: UDUserAccountCryptWallet) async throws -> StripePaymentDetailsResponse {
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
        let response: StripePaymentDetailsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func prepareStripePaymentDetails(for wallet: UDUserAccountCryptWallet) async throws -> StripePaymentDetails {
        try await refreshUserCart()
        do {
            let detailsResponse = try await loadStripePaymentDetails(for: wallet)
            let details = StripePaymentDetails(amount: udCart.calculations.totalAmountDue,
                                               clientSecret: detailsResponse.clientSecret,
                                               orderId: detailsResponse.orderId)
            cachedPaymentDetails = details
            return details
        } catch {
            if let cachedPaymentDetails {
                return cachedPaymentDetails
            }
            throw error
        }
    }
    
    func loadCartParkingProducts(in cart: UDUserCart) async {
        var cart = cart
        var products = cart.products
        
        await withTaskGroup(of: UDProduct.self) { group in
            for product in products {
                group.addTask {
                    switch product {
                    case .domain(var domain):
                        var availableProducts = domain.availableProducts ?? []
                        
                        // Check for ENS registry fee
                        if domain.isENSDomain {
                            if let ensStatus = try? await self.getENSDomainStatus(domainName: domain.domain.name) {
                                domain.ensStatus = ensStatus
                            }
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
                    case .parking, .ensAutoRenewal:
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
    
    func removeCartUnsupportedProducts(in cart: [UDProduct]) async throws {
        let productsToRemove = filterUnsupportedProductsFrom(products: cart)
        
        if !productsToRemove.isEmpty {
            try await removeProductsFromCart(productsToRemove, shouldRefreshCart: false)
        }
    }
    
    func filterUnsupportedProductsFrom(products: [UDProduct]) -> [UDProduct] {
        products.flatMap { product -> [UDProduct] in
            switch product {
            case .domain(let domain):
                /// Remove all domains except what user has selected for purchase
                if domainsToPurchase.first(where: { $0.name == domain.domain.name }) == nil {
                    return [product]
                }
                return domain.hiddenProducts
            default:
                return [product]
            }
        }
    }
    
    func loadDomainParkingProductCart(for domain: DomainProductDetails) async throws -> UDProduct {
        let urlString = URLSList.DOMAINS_PARKING_PRODUCT_URL(domain: domain.name)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        return try await makeFirebaseDecodableAPIDataRequest(request)
    }
    
    func loadUserCartCalculations() async throws -> UserCartCalculationsResponse {
        let queryComponents = ["applyPromoCredits" : String(checkoutData.isPromoCreditsOn),
                               "applyStoreCredits" : String(checkoutData.isStoreCreditsOn),
                               "discountCode" : checkoutData.discountCode.trimmedSpaces,
                               "durationsMap" : checkoutData.getDurationsMapString(),
                               "zipCode" : checkoutData.usaZipCode.trimmedSpaces]
        
        let urlString = URLSList.USER_CART_CALCULATIONS_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: UserCartCalculationsResponse = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    enum PurchaseDomainsError: String, LocalizedError {
        case udAccountHasUnpaidVault
    }
}

// MARK: - Private methods
private extension DomainToPurchase {
    init(domainProduct: FirebasePurchaseDomainsService.DomainProductItem) {
        self.name = domainProduct.domain.name
        self.price = domainProduct.price
        self.metadata = domainProduct.jsonData()
    }
}



