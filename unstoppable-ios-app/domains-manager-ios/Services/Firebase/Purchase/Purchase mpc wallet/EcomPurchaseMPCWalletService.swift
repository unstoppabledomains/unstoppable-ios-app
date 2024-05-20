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
    private var ongoingPurchaseSession: PurchaseSessionDescription?
    private var isGuestLogin: Bool { true }
    
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
            logMPC("Will make data request \(apiRequest)")
            return try await super.makeFirebaseAPIDataRequest(apiRequest)
        } catch {
            logMPC("Error data request \(apiRequest):\(error)")
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
            logMPC("Will make decodable request \(apiRequest)")
            return try await super.makeFirebaseDecodableAPIDataRequest(apiRequest,
                                                                       using: keyDecodingStrategy,
                                                                       dateDecodingStrategy: dateDecodingStrategy)
        } catch {
            logMPC("Error decoding request \(apiRequest):\(error)")
            appContext.analyticsService.log(event: .purchaseFirebaseRequestError,
                                            withParameters: [.error: error.localizedDescription,
                                                             .value: apiRequest.url.absoluteString])
            if shouldCheckForRequestError {
                cartStatus = .failedToLoadCalculations { self.refreshUserCartAsync() }
            }
            throw error
        }
    }
    
    override func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        guard let sessionId = ongoingPurchaseSession?.sessionId else { throw PurchaseMPCWalletError.noSessionId }
        
        let url = apiRequest.url.appending(queryItems: [.init(name: "guestUuid", value: sessionId)])
        let firebaseAPIRequest = APIRequest(url: url,
                                            headers: apiRequest.headers,
                                            body: apiRequest.body,
                                            method: apiRequest.method)
        
        return firebaseAPIRequest
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
    
    override func loadUserProfile() async throws -> Ecom.UDUserProfileResponse {
        if isGuestLogin {
            return .init(promoCredits: 0, referralCode: "", storeCredits: 0, uid: "")
        }
        return try await super.loadUserProfile()
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
        ongoingPurchaseSession = nil
        await logout()
    }
    
    func refreshCart() async throws {
        try await refreshUserCart()
    }
    
    func guestAuthWith(credentials: MPCPurchaseUDCredentials) async throws {
        await prepareBeforeAuth()
        self.ongoingPurchaseSession = PurchaseSessionDescription(email: credentials.email, sessionId: UUID().uuidString)
        checkoutData.isPromoCreditsOn = false
        checkoutData.isStoreCreditsOn = false
        try await didAuthorise()
    }
    
    func purchaseMPCWallet() async throws {
        isAutoRefreshCartSuspended = true
        try await purchaseProductsInTheCart(with: .init(email: ongoingPurchaseSession?.email),
                                            totalAmountDue: udCart.calculations.totalAmountDue)
        ongoingPurchaseSession?.orderId = cachedPaymentDetails?.orderId
        try await waitForMPCWalletIsCreated()
        isAutoRefreshCartSuspended = false
    }
    
    func validateCredentialsForTakeover(credentials: MPCActivateCredentials) async throws -> Bool {
        do {
            try await makeSetupWalletRequestFor(credentials: credentials, preview: true)
            return true
        } catch NetworkLayerError.badResponseOrStatusCode(let code, _, _) where code == 400 { // 400 returned when email already in use
            return false
        } catch {
            throw error
        }
    }
    
    func runTakeover(credentials: MPCActivateCredentials) async throws {
        try await makeSetupWalletRequestFor(credentials: credentials, preview: false)
        try await waitForWalletIsReadyForActivation()
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
        if isGuestLogin {
            return false
        }
        
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
        case noSessionId
        case noSessionDetails
        case waitWalletClaimedTimeout
    }
    
    struct PurchaseSessionDescription {
        let email: String
        let sessionId: String
        var orderId: Int?
        var wallet: EcomMPCWallet?
    }
    
    struct EcomMPCWallet: Codable {
        let address: String
        let verified: Bool
    }
}

// MARK: - Private methods
private extension EcomPurchaseMPCWalletService {
    func waitForMPCWalletIsCreated() async throws {
        for i in 0..<60 {
            do {
                let walletInfo = try await getMPCWalletInfo()
                
                if walletInfo.verified {
                    /// This means this UD account already has MPC wallet and takeover already done
                    throw MPCWalletPurchaseError.walletAlreadyPurchased
                } else {
                    return
                }
            } catch { }
            
            await Task.sleep(seconds: 0.5)
        }
    }
    
    func getMPCWalletInfo() async throws -> EcomMPCWallet {
        guard let ongoingPurchaseSession,
              let orderId = ongoingPurchaseSession.orderId else { throw PurchaseMPCWalletError.noSessionDetails }
        
        let queryComponents = ["email" : ongoingPurchaseSession.email,
                               "orderId" : String(orderId)]
        let urlString = URLSList.USER_MPC_WALLET_URL.appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        
        let response: EcomMPCWallet = try await makeFirebaseDecodableAPIDataRequest(request)
        return response
    }
    
    func makeSetupWalletRequestFor(credentials: MPCActivateCredentials,
                                   preview: Bool) async throws {
        guard let wallet = ongoingPurchaseSession?.wallet else { throw PurchaseMPCWalletError.noSessionDetails }
        
        struct RequestBody: Encodable {
            let walletEmail: String
            let password: String
            let preview: Bool
        }
        
        let body = RequestBody(walletEmail: credentials.email, password: credentials.password, preview: preview)
        let urlString = URLSList.USER_MPC_SETUP_URL(walletAddress: wallet.address)
        let request = try APIRequest(urlString: urlString,
                                     body: body,
                                     method: .post)
        
        try await makeFirebaseAPIDataRequest(request)
    }
    
    func waitForWalletIsReadyForActivation() async throws {
        for i in 0..<60 {
            let isReady = try await checkMPCWalletReady()
            if isReady {
                return
            }
            await Task.sleep(seconds: 0.5)
        }
        
        throw PurchaseMPCWalletError.waitWalletClaimedTimeout
    }
    
    func checkMPCWalletReady() async throws -> Bool {
        guard let ongoingPurchaseSession,
              let wallet = ongoingPurchaseSession.wallet else { throw PurchaseMPCWalletError.noSessionDetails }
        
        struct Response: Decodable {
            let inProgress: Bool
        }
        
        let email = ongoingPurchaseSession.email
        let queryComponents = ["email" : ongoingPurchaseSession.email]
        let urlString = URLSList.USER_MPC_STATUS_URL(walletAddress: wallet.address).appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: urlString,
                                     method: .get)
        
        let response: Response = try await makeFirebaseDecodableAPIDataRequest(request)
        return !response.inProgress
    }

}
