//
//  NetworkService+PAv3.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.05.2024.
//

import Foundation

// MARK: - PAv3 Interaction through Profiles API
extension NetworkService {
    func verifyDomainSignUpStatus(domain: DomainItem) async throws -> Bool {
        let status = try await getDomainSignUpStatus(domain: domain)
        return status.isSignedUp
    }
    
    func signUpDomain(domain: DomainItem) async throws {
        struct RequestBody: Encodable {
            let address: String
            let message: String
            let signature: String
        }
        
        // 1. Check status and get message to sign
        let status = try await getDomainSignUpStatus(domain: domain)
        guard let message = status.message else {
            if status.isSignedUp {
                return
            }
            throw ProfileDomainError.failedToGetMessageToSignUp
        }
        
        // 2. Sign the message
        let signature = try await domain.personalSign(message: message)
        
        // 3. Submit signature
        let url = ProfileDomainURLSList.checkWalletSignUpStatusURL(domain: domain.name)
        let address = status.address
        let body = RequestBody(address: address,
                               message: message,
                               signature: signature)
        try await makeProfilesAuthorizedRequest(url: url, method: .post, body: body, domain: domain)
    }
}

// MARK: - Private methods
private extension NetworkService {
    func getDomainSignUpStatus(domain: DomainItem) async throws -> DomainSignUpStatusResponse {
        let url = ProfileDomainURLSList.checkWalletSignUpStatusURL(domain: domain.name)
        let response: DomainSignUpStatusResponse = try await makeProfilesAuthorizedDecodableRequest(url: url,
                                                                                                    method: .get,
                                                                                                    domain: domain)
        return response
    }
    
    struct DomainSignUpStatusResponse: Codable {
        let address: String
        let type: String?
        let message: String?
        
        var isSignedUp: Bool {
            type != nil
        }
    }
    
    func makeProfilesAuthorizedDecodableRequest<T: Decodable>(url: String,
                                                                      method: HttpRequestMethod,
                                                                      body: Encodable? = nil,
                                                                      domain: DomainItem) async throws -> T {
        let apiRequest = try await prepareProfileAuthorizedAPIRequestWith(url: url, method: method, body: body, domain: domain)
        let response: T = try await makeDecodableAPIRequest(apiRequest)
        return response
    }
    
    @discardableResult
    func makeProfilesAuthorizedRequest(url: String,
                                               method: HttpRequestMethod,
                                               body: Encodable? = nil,
                                               domain: DomainItem) async throws -> Data {
        let apiRequest = try await prepareProfileAuthorizedAPIRequestWith(url: url, method: method, body: body, domain: domain)
        let data = try await makeAPIRequest(apiRequest)
        return data
    }
    
    func prepareProfileAuthorizedAPIRequestWith(url: String,
                                                        method: HttpRequestMethod,
                                                        body: Encodable? = nil,
                                                        domain: DomainItem) async throws -> APIRequest {
        let persistedSignature = try await getOrCreateAndStorePersistedProfileSignature(for: domain)
        let domain = persistedSignature.domainName
        let expires = persistedSignature.expires
        let signature = persistedSignature.sign
        let expiresString = "\(expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expiresString,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        let apiRequest = try APIRequest(urlString: url, body: body, method: method, headers: headers)
        
        return apiRequest
    }
}

// MARK: - Private methods
private extension NetworkService {
    enum ProfileDomainURLSList {
        static var baseURL: String { NetworkConfig.migratedBaseUrl }
        
        static var profileAPIURL: String { baseURL.appendingURLPathComponents("profile") }
        static var userAPIURL: String { profileAPIURL.appendingURLPathComponents("user") }
        
        static func checkWalletSignUpStatusURL(domain: DomainName) -> String {
            userAPIURL.appendingURLPathComponents(domain, "wallet")
        }
    }
    
    enum ProfileDomainError: String, LocalizedError {
        case failedToGetMessageToSignUp
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
