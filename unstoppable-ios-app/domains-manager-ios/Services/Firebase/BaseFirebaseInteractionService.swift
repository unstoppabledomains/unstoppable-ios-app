//
//  BaseFirebaseInteractionService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 30.10.2023.
//

import Foundation

class BaseFirebaseInteractionService {
    
    enum URLSList {
        static var baseURL: String {
            NetworkConfig.migratedBaseUrl
        }
        static var baseAPIURL: String { baseURL.appendingURLPathComponent("api") }
        
        static var logoutURL: String { baseAPIURL.appendingURLPathComponents("user", "session", "clear") }
        
        static var USER_URL: String { baseAPIURL.appendingURLPathComponent("user") }
        static var USER_PROFILE_URL: String { USER_URL.appendingURLPathComponent("profile") }
        
        static var DOMAIN_URL: String { baseAPIURL.appendingURLPathComponent("domain") }
        static var DOMAIN_SEARCH_URL: String { DOMAIN_URL.appendingURLPathComponents("search", "internal") }
        static var DOMAIN_AI_SUGGESTIONS_URL: String { DOMAIN_URL.appendingURLPathComponents("search", "ai-suggestions") }
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
        static var STORE_CHECKOUT_URL: String { baseAPIURL.appendingURLPathComponents("store", "checkout") }
        static var CRYPTO_WALLETS_URL: String { baseAPIURL.appendingURLPathComponent("crypto-wallets") }

    }
    
    let authHeaderKey = "auth-firebase-id-token"
    let firebaseAuthService: FirebaseAuthService
    let firebaseSigner: UDFirebaseSigner
    
    init(firebaseAuthService: FirebaseAuthService,
         firebaseSigner: UDFirebaseSigner) {
        self.firebaseAuthService = firebaseAuthService
        self.firebaseSigner = firebaseSigner
    }
    
    func logout() async {
        _ = try? await makeFirebaseAPIDataRequest(.init(urlString: URLSList.logoutURL,
                                                    method: .post))
        firebaseAuthService.logout()
    }
    
    @discardableResult
    func makeFirebaseAPIDataRequest(_ apiRequest: APIRequest) async throws -> Data {
        do {
            let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
            let response = try await NetworkService().makeAPIRequest(firebaseAPIRequest)
            return response
        } catch {
            Debugger.printFailure("Failed to make firebase api request: \(error.localizedDescription) for \(apiRequest.url)")
            throw error
        }
    }
    
    func makeFirebaseDecodableAPIDataRequest<T: Decodable>(_ apiRequest: APIRequest,
                                                           using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                           dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T {
        let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
        let response: T = try await NetworkService().makeDecodableAPIRequest(firebaseAPIRequest,
                                                                             using: keyDecodingStrategy,
                                                                             dateDecodingStrategy: dateDecodingStrategy)
        return response
    }
    
    func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        let idToken = try await getIdToken()
        
        var headers = apiRequest.headers.appending(dict2: NetworkConfig.disableFastlyCacheHeader)
        headers[authHeaderKey] = idToken
        let firebaseAPIRequest = APIRequest(url: apiRequest.url,
                                            headers: headers,
                                            body: apiRequest.body,
                                            method: apiRequest.method)
        
        return firebaseAPIRequest
    }
}

// MARK: - Open methods
extension BaseFirebaseInteractionService {
    func getIdToken() async throws -> String {
        try await firebaseAuthService.getIdToken()
    }
}
