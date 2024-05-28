//
//  EcomMPCPriceFetcher.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.05.2024.
//

import Foundation

final class EcomMPCPriceFetcher: EcomPurchaseInteractionService {
    
    static let shared = EcomMPCPriceFetcher()
    private let sessionId = UUID().uuidString
    private var fetchPriceTask: Task<Int, Error>?
    private var price: Int?
    
    private init() {
        let signer = UDFirebaseSigner()
        super.init(firebaseAuthService: FirebaseAuthService(firebaseSigner: signer,
                                                            refreshTokenStorage: FirebaseAuthInMemoryStorage()),
                   firebaseSigner: signer,
                   checkoutData: .init())
    }
    
    override func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        let url = apiRequest.url.appending(queryItems: [.init(name: "guestUuid", value: sessionId)])
        let firebaseAPIRequest = APIRequest(url: url,
                                            headers: apiRequest.headers,
                                            body: apiRequest.body,
                                            method: apiRequest.method)
        
        return firebaseAPIRequest
    }
    
    override func filterUnsupportedProductsFrom(products: [Ecom.UDProduct]) -> [Ecom.UDProduct] {
        []
    }
    
    override func loadUserProfile() async throws -> Ecom.UDUserProfileResponse {
        .init(promoCredits: 0, referralCode: "", storeCredits: 0, uid: "")
    }
    
    func fetchPrice() async throws -> Int {
        if let price {
            return price
        }
        
        if let fetchPriceTask {
            return try await fetchPriceTask.value
        }
        
        let task = Task {
            try await addProductsToCart([.mpcWallet(.init())], shouldRefreshCart: true)
            for product in udCart.products {
                if case .mpcWallet(let uDProductFB_MPCWallet) = product {
                    let price = uDProductFB_MPCWallet.price
                    return price
                }
            }
            throw EcomMPCPriceFetcherError.failedToFetchPrice
        }
        
        self.fetchPriceTask = task
        let price = try await task.value
        self.price = price
        self.fetchPriceTask = nil
        
        Task.detached {
            await self.logout()
        }
        
        return price
    }
    
    enum EcomMPCPriceFetcherError: String, LocalizedError {
        case failedToFetchPrice
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

