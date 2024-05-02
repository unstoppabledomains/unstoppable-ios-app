//
//  NetworkService+PAv3.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.05.2024.
//

import Foundation

// MARK: - PAv3 Interaction through Profiles API
extension NetworkService {
    func verifyDomainPAv3SignUpStatus(domain: DomainItem) async throws -> Bool {
        let status = try await getDomainSignUpStatus(domain: domain)
        return status.isSignedUp
    }
    
    func signUpDomainInPAv3(domain: DomainItem) async throws {
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
    
    func ensureDomainSignedUpInPAv3(domain: DomainItem) async throws {
        let isSignedUp = try await verifyDomainPAv3SignUpStatus(domain: domain)
        if !isSignedUp {
            try await signUpDomainInPAv3(domain: domain)
        }
    }
    
    private func getDomainSignUpStatus(domain: DomainItem) async throws -> DomainSignUpStatusResponse {
        let url = ProfileDomainURLSList.checkWalletSignUpStatusURL(domain: domain.name)
        let response: DomainSignUpStatusResponse = try await makeProfilesAuthorizedDecodableRequest(url: url,
                                                                                                    method: .get,
                                                                                                    domain: domain)
        return response
    }
    
    private struct DomainSignUpStatusResponse: Codable {
        let address: String
        let type: String?
        let message: String?
        
        var isSignedUp: Bool {
            type != nil
        }
    }
}

// MARK: - Fetch domain & info
extension NetworkService {
    func fetchDomainsIn(wallet: HexAddress) async throws -> [DomainItem] {
        let take = 100
        var hasMore = true
        var cursor: String?
        var domains: [DomainItem] = []
        
        while hasMore {
            let response = try await fetchDomainsIn(wallet: wallet, 
                                                    take: take,
                                                    cursor: cursor)
            let domainsInResponse = response.data.map { DomainItem(name: $0.domain,
                                                                   ownerWallet: wallet,
                                                                   blockchain: $0.blockchainType()) }
            domains.append(contentsOf: domainsInResponse)
            cursor = response.cursor
            hasMore = response.hasMore
        }
        
        return domains
    }
    
    private func fetchDomainsIn(wallet: HexAddress,
                                take: Int,
                                cursor: String?) async throws -> DomainsResponse {
        var queryParameters: [String : String] = ["take" : String(take)]
        if let cursor {
            queryParameters[cursor] = cursor
        }
        let url = ProfileDomainURLSList
            .walletDomainsURL(wallet: wallet)
            .appendingURLQueryComponents(queryParameters)
        let request = try APIRequest(urlString: url, method: .get)
        let response: DomainsResponse = try await makeDecodableAPIRequest(request)
        return response
    }
    
    private struct DomainsResponse: Decodable {
        
        let data: [Domain]
        let meta: Meta
        
        var hasMore: Bool { meta.pagination.hasMore }
        var cursor: String? { meta.pagination.cursor }
        
        struct Domain: Codable {
            let domain: String
            let chain: String? // TODO: - Request this field from Profiles API
            
            func blockchainType() -> BlockchainType {
                BlockchainType(rawValue: chain ?? "") ?? .Matic
            }
        }
        
        struct Meta: Decodable {
            let totalCount: Int
            let pagination: Pagination
            
            private enum CodingKeys: String, CodingKey {
                case totalCount = "total_count"
                case pagination
            }
            
            struct Pagination: Codable {
                let cursor: String?
                let hasMore: Bool
                let take: Int
            }
        }
    }
}

// MARK: - Fetch domain & info
extension NetworkService {
    func fetchPendingTxsFor(domain: DomainItem) async throws -> [TransactionItem] {
        let wallet = try domain.findOwnerWallet()
        switch wallet.type {
        case .externalLinked:
            guard getPersistedProfileSignature(for: domain) != nil else { return [] }
        default:
            Void()
        }

        let url = ProfileDomainURLSList.domainRecordsManageURL(domain: domain.name)
        let response: DomainOperationsResponse = try await makeProfilesAuthorizedDecodableRequest(url: url,
                                                                                                  method: .get,
                                                                                                  domain: domain)
        let txs = response.items.map { $0.createTxItem() }
        return txs
    }

    private struct DomainOperationsResponse: Decodable {
        let items: [Operation]
        let next: String?
        
        struct Operation: Decodable {
            let id: String
            let type: String
            let status: String // DOMAIN_UPDATE
            let domain: String
            
            func createTxItem() -> TransactionItem {
                TransactionItem(id: nil,
                                transactionHash: id,
                                domainName: domain,
                                isPending: true,
                                type: nil,
                                operation: getTxOperation(),
                                gasPrice: nil,
                                nonce: nil,
                                domainId: nil)
            }
            
            private func getTxOperation() -> TxOperation? {
                switch status {
                case "DOMAIN_UPDATE":
                    return .recordUpdate
                default:
                    return nil
                }
            }
        }
    }
}

// MARK: - Private methods
private extension NetworkService {
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
        
        static func walletDomainsURL(wallet: HexAddress) -> String {
            userAPIURL.appendingURLPathComponents(wallet, "domains")
        }
        
        static func domainRecordsManageURL(domain: DomainName) -> String {
            userAPIURL.appendingURLPathComponents(domain, "records", "manage")
        }
    }
    
    enum ProfileDomainError: String, LocalizedError {
        case failedToGetMessageToSignUp
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
