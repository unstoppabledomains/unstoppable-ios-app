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
        try? await makeFirebaseAPIDataRequest(.init(urlString: URLSList.logoutURL,
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
}

// MARK: - Open methods
extension BaseFirebaseInteractionService {
    func getIdToken() async throws -> String {
        try await firebaseAuthService.getIdToken()
    }
}

// MARK: - Private methods
private extension BaseFirebaseInteractionService {
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
