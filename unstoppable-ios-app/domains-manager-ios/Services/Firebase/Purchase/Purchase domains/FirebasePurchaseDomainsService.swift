//
//  FirebasePurchaseDomainsService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 31.10.2023.
//

import Foundation
import Combine

final class FirebasePurchaseDomainsService: EcomPurchaseInteractionService {
    
    @Published var cartStatus: PurchaseDomainCartStatus
    var cartStatusPublisher: Published<PurchaseDomainCartStatus>.Publisher { $cartStatus }
    
    private var cancellables: Set<AnyCancellable> = []
    private var domainsToPurchase: [DomainToPurchase] = []

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
        !isAutoRefreshCartSuspended && !domainsToPurchase.isEmpty
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
        products.flatMap { product -> [Ecom.UDProduct] in
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
    
    override func cartContainsUnsupportedProducts() {
        cartStatus = .hasUnpaidDomains
        appContext.analyticsService.log(event: .accountHasUnpaidDomains, withParameters: nil)
    }
    
    override func didRefreshCart() {
        cartStatus = .ready(cart: createCartFromUDCart(udCart))
    }
}

// MARK: - PurchaseDomainsServiceProtocol
extension FirebasePurchaseDomainsService: PurchaseDomainsServiceProtocol {
    func searchForDomains(key: String,
                           tlds: Set<String>) -> AsyncThrowingStream<[DomainToPurchase], Error> {
        AsyncThrowingStream { continuation in
            Task {
                try? await withThrowingTaskGroup(of: Void.self) { group in
                    TLDCategory.allCases.forEach { tld in
                        let start = Date()
                        group.addTask {
                            do {
                                let searchResult = try await self.searchForEcommDomains(key: key,
                                                                                        tlds: tlds,
                                                                                        tldCategory: tld)
                                let domains = self.transformDomainProductItemsToDomainsToPurchase(searchResult.exact)
                                continuation.yield(domains)
                            } catch { }
                        }
                    }
                    
                    for try await _ in group { }
                }
                
                continuation.finish()
            }
        }
    }
    
    func aiSearchForDomains(hint: String) async throws -> [DomainToPurchase] {
        let domainProducts = try await aiSearchForFBDomains(hint: hint)
        let domains = transformDomainProductItemsToDomainsToPurchase(domainProducts)
        return domains
    }
    
    func getDomainsSuggestions(hint: String, tlds: Set<String>) async throws -> [DomainToPurchase] {
        let domainProducts = try await getDomainsSearchSuggestions(hint: hint,
                                                                   tlds: tlds)
        let domains = transformDomainProductItemsToDomainsToPurchase(domainProducts)
        return domains
    }
    
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
    
    func setDomainsToPurchase(_ domains: [DomainToPurchase]) async throws {
        isAutoRefreshCartSuspended = true
        cartStatus = .ready(cart: .empty)
        self.domainsToPurchase = domains
        try await addDomainsToCart(domains)
        isAutoRefreshCartSuspended = false
    }
    
    func reset() async {
        cartStatus = .ready(cart: .empty)
        cachedPaymentDetails = nil
        self.domainsToPurchase = []
        await logout()
    }
    
    func getSupportedWalletsToMint() async throws -> [PurchasedDomainsWalletDescription] {
        let userWallets = try await loadUserCryptoWallets()
        return userWallets.map { PurchasedDomainsWalletDescription(ecomWallet: $0) }
    }
    
    func getPreferredWalletToMint() async throws -> PurchasedDomainsWalletDescription? {
        guard firebaseAuthService.isAuthorised else { throw PurchaseDomainsError.unauthorized }
        
        if let mintingWallet = try await getEcommMintingWallet() {
            let wallet = PurchasedDomainsWalletDescription(ecomWallet: mintingWallet)
            return wallet
        }
        return nil
    }
    
    func refreshCart() async throws {
        try await refreshUserCart()
    }
    
    func purchaseDomainsInTheCartAndMintTo(wallet: PurchasedDomainsWalletDescription) async throws {
        isAutoRefreshCartSuspended = true
        let userWallet = try Ecom.UDUserAccountCryptWallet.objectFromDataThrowing(wallet.metadata ?? Data())
        try await purchaseProductsInTheCart(with: .init(wallet: userWallet),
                                            totalAmountDue: udCart.calculations.totalAmountDue)
    }
}

// MARK: - Private methods
private extension FirebasePurchaseDomainsService {
    func searchForEcommDomains(key: String,
                               tlds: Set<String>,
                               tldCategory: TLDCategory) async throws -> SearchDomainsResponse {
        var searchResponse = try await makeSearchDomainsRequestWith(key: key,
                                                                    tlds: tlds,
                                                                    tldCategory: tldCategory)
        searchResponse.exact = searchResponse.exact
        return searchResponse
    }
    
    func getEcommMintingWallet() async throws -> Ecom.UDUserAccountCryptWallet? {
        struct Response: Codable {
            let cryptoWallet: Ecom.UDUserAccountCryptWallet?
        }
        
        let urlString = URLSList.USER_MINTING_WALLET_URL
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: Response = try await makeFirebaseDecodableAPIDataRequest(request)
        
        return response.cryptoWallet
    }
    
    func getDomainsSearchSuggestions(hint: String, tlds: Set<String>) async throws -> [Ecom.DomainProductItem] {
        let queryComponents: [String : String] = ["q" : hint,
                                                  "page" : "1",
                                                  "rowsPerPage" : "10"]
        var urlString = URLSList.DOMAIN_SUGGESTIONS_URL.appendingURLQueryComponents(queryComponents)
        for tld in tlds {
            urlString += "&extension[]=\(tld)"
        }
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: SuggestDomainsResponse = try await NetworkService().makeDecodableAPIRequest(request)
        return response.suggestions
    }
    
    func aiSearchForFBDomains(hint: String) async throws -> [Ecom.DomainProductItem] {
        let queryComponents: [String : String] = ["extension" : "All",
                                                  "phrase" : hint]
        let urlString = URLSList.DOMAIN_AI_SUGGESTIONS_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: SuggestDomainsResponse = try await NetworkService().makeDecodableAPIRequest(request)
        return response.suggestions
    }
    
    func makeSearchDomainsRequestWith(key: String,
                                      tlds: Set<String>,
                                      tldCategory: TLDCategory) async throws -> SearchDomainsResponse {
        let queryComponents: [String : String] = ["q" : key]
        var urlString = URLSList.DOMAIN_UD_SEARCH_URL(tld: tldCategory).appendingURLQueryComponents(queryComponents)
        for tld in tlds {
            urlString += "&includeDomainEndings[]=\(tld)"
        }
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let response: SearchDomainsResponse = try await NetworkService().makeDecodableAPIRequest(request)
        return response
    }
    
    func getENSDomainStatus(domainName: String) async throws -> Ecom.ENSDomainProductStatusResponse {
        let urlString = URLSList.DOMAIN_ENS_STATUS_URL(domain: domainName)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        let status: Ecom.ENSDomainProductStatusResponse = try await makeFirebaseDecodableAPIDataRequest(request,
                                                                                                   dateDecodingStrategy: .defaultDateDecodingStrategy())
        return status
    }
    
    func transformDomainProductItemsToDomainsToPurchase(_ productItems: [Ecom.DomainProductItem]) -> [DomainToPurchase] {
        productItems
            .map { DomainToPurchase(domainProduct: $0) }
    }
}

// MARK: - Cart
private extension FirebasePurchaseDomainsService {
    func createCartFromUDCart(_ udCart: Ecom.UDUserCart) -> PurchaseDomainsCart {
        let domainProducts = udCart.products.compactMap { product in
            switch product {
            case .domain(let domainProductItem):
                return domainProductItem
            case .parking, .ensAutoRenewal, .unknown, .mpcWallet:
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
   
    func loadCartParkingProducts(in cart: Ecom.UDUserCart) async {
        var cart = cart
        var products = cart.products
        
        await withTaskGroup(of: Ecom.UDProduct.self) { group in
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
                    case .parking, .ensAutoRenewal, .unknown, .mpcWallet:
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

    func loadDomainParkingProductCart(for domain: Ecom.DomainProductDetails) async throws -> Ecom.UDProduct {
        let urlString = URLSList.DOMAINS_PARKING_PRODUCT_URL(domain: domain.name)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        return try await makeFirebaseDecodableAPIDataRequest(request)
    }
   
    enum PurchaseDomainsError: String, LocalizedError {
        case udAccountHasUnpaidVault
        case unauthorized
    }
}

// MARK: - Private methods
private extension DomainToPurchase {
    init(domainProduct: Ecom.DomainProductItem) {
        self.name = domainProduct.domain.name
        self.price = domainProduct.price
        self.metadata = domainProduct.jsonData()
        self.isTaken = !domainProduct.availability
        self.isAbleToPurchase = domainProduct.isAbleToPurchase
    }
}

// MARK: - Private methods
private extension PurchasedDomainsWalletDescription {
    init(ecomWallet: Ecom.UDUserAccountCryptWallet) {
        self.address = ecomWallet.address
        self.metadata = ecomWallet.jsonData()
    }
}
