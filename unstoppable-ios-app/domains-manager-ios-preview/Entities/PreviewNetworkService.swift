//
//  PreviewNetworkService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

struct NetworkService {
    struct DebugOptions {
#if TESTFLIGHT
        static let shouldCrashIfBadResponse = false // FALSE if ignoring API errors
#else
        static let shouldCrashIfBadResponse = false // always FALSE
#endif
    }
    
    
    static let startBlockNumberMainnet = "0x8A958B" // Registry Contract creation block
    static let startBlockNumberMRinkeby = "0x7232BC"
    
    enum HttpRequestMethod: String {
        case post = "POST"
        case get = "GET"
        case patch = "PATCH"
        case delete = "DELETE"
        
        var string: String { self.rawValue }
    }
    static let httpSuccessRange = 200...299
    static let headers = [
        "Accept": "application/json",
        "Content-Type": "application/json"]
    
    static let appVersionHeaderKey = "X-IOS-APP-VERSION"
    static var profilesAPIHeader: [String : String] { ["" : ""] }
    
    init() {
    }
    
    func makeDecodableAPIRequest<T: Decodable>(_ apiRequest: APIRequest,
                                               using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                               dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T {
        let data = try await makeAPIRequest(apiRequest)
        
        if let object = T.objectFromData(data,
                                         using: keyDecodingStrategy,
                                         dateDecodingStrategy: dateDecodingStrategy) {
            return object
        } else {
            throw NetworkLayerError.parsingDomainsError
        }
    }
    
    func fetchGlobalReverseResolution(for identifier: HexAddress) async throws -> GlobalRR? {
        return GlobalRR(address: identifier,
                        name: identifier,
                        avatarUrl: nil,
                        imageUrl: nil)
    }
    
    func makeAPIRequest(_ apiRequest: APIRequest) async throws -> Data {
        try await fetchData(for: apiRequest.url,
                            body: apiRequest.body,
                            method: apiRequest.method,
                            extraHeaders: apiRequest.headers)
    }
    
    @discardableResult
    func fetchDataFor(endpoint: Endpoint,
                      method: HttpRequestMethod) async throws -> Data {
        guard let url = endpoint.url else { throw NetworkLayerError.creatingURLFailed }
        let data = try await fetchData(for: url, body: endpoint.body, method: method, extraHeaders: endpoint.headers)
        return data
    }
    
    func fetchDecodableDataFor<T: Decodable>(endpoint: Endpoint,
                                             method: HttpRequestMethod,
                                             using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                             dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T {
        let data = try await fetchDataFor(endpoint: endpoint, method: method)
        guard let entity = T.objectFromData(data,
                                            using: keyDecodingStrategy,
                                            dateDecodingStrategy: dateDecodingStrategy) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return entity
    }
    
    func fetchData(for url: URL,
                   body: String = "",
                   method: HttpRequestMethod = .post,
                   extraHeaders: [String: String]  = [:]) async throws -> Data {
        let urlRequest = urlRequest(for: url, body: body, method: method, extraHeaders: extraHeaders)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest, delegate: nil)
            guard let response = response as? HTTPURLResponse else {
                throw NetworkLayerError.badResponseOrStatusCode(code: 0, message: "No Http response")
            }
            
            if response.statusCode < 300 {
                return data
            } else {
                if response.statusCode == Constants.backEndThrottleErrorCode {
                    Debugger.printWarning("Request failed due to backend throttling issue")
                    throw NetworkLayerError.backendThrottle
                }
                let message = extractErrorMessage(from: data)
                throw NetworkLayerError.badResponseOrStatusCode(code: response.statusCode, message: "\(message)")
            }
        } catch {
            let error = error as NSError
            switch error.code {
            case NSURLErrorNetworkConnectionLost:
                throw NetworkLayerError.connectionLost
            case NSURLErrorCancelled:
                throw NetworkLayerError.requestCancelled
            case NSURLErrorNotConnectedToInternet:
                throw NetworkLayerError.notConnectedToInternet
            default:
                if let networkError = error as? NetworkLayerError {
                    throw networkError
                }
                Debugger.printFailure("Error \(error.code) - \(error.localizedDescription)", critical: false)
                throw NetworkLayerError.noMessageError
            }
        }
    }
    
    private func extractErrorMessage(from taskData: Data?) -> String {
        guard let responseData = taskData,
              let errorResponse = try? JSONDecoder().decode(MobileAPiErrorResponse.self, from: responseData) else {
            return ""
        }
        
        let message = errorResponse.errors
            .map({($0.code ?? "") + " / " + ($0.message ?? "")})
            .joined(separator: " ")
        return message
    }
    
    private func urlRequest(for url: URL,
                            body: String = "",
                            method: HttpRequestMethod = .post,
                            extraHeaders: [String: String]  = [:]) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = method.string
        urlRequest.httpBody = body.data(using: .utf8)
        Self.headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)}
        extraHeaders.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)}
        
        urlRequest.addValue(Version.getCurrentAppVersionString() ?? "version n/a", forHTTPHeaderField: Self.appVersionHeaderKey)
        
        Debugger.printInfo(topic: .Network, "--- REQUEST TO ENDPOINT")
        Debugger.printInfo(topic: .Network, "METHOD: \(method) | URL: \(url.absoluteString)")
        Debugger.printInfo(topic: .Network, "BODY: \(body)")
        Debugger.printInfo(topic: .Network, "HEADERS: \(urlRequest.allHTTPHeaderFields ?? [:])")
        
        return urlRequest
    }
}

extension NetworkService {
    public func fetchPublicProfile(for domain: DomainItem, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        try await fetchPublicProfile(for: domain.name, fields: fields)
    }
    
    public func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        MockEntitiesFabric.DomainProfile.createPublicProfile(domain: domainName,
                                                             walletBalance: MockEntitiesFabric.DomainProfile.createPublicProfileWalletBalances())
    }
    
    public func refreshDomainBadges(for domain: DomainItem) async throws -> RefreshBadgesResponse {
        .init(ok: true, refresh: true, next: Date())
    }
    public func fetchBadgesInfo(for domain: DomainItem) async throws -> BadgesInfo {
        try await fetchBadgesInfo(for: domain.name)
    }
    public func fetchBadgesInfo(for domainName: DomainName) async throws -> BadgesInfo {
        MockEntitiesFabric.Badges.createBadgesInfo()
    }
    public func fetchBadgeDetailedInfo(for badge: BadgesInfo.BadgeInfo) async throws -> BadgeDetailedInfo {
        .init(badge: .init(code: "", name: "", logo: "", description: ""), usage: .init(rank: 0, holders: 1, domains: 1, featured: []))
    }
    public func fetchUserDomainProfile(for domain: DomainItem, fields: Set<GetDomainProfileField>) async throws -> SerializedUserDomainProfile {
        .init(profile: .init(),
              messaging: .init(),
              socialAccounts: .init(),
              humanityCheck: .init(verified: false),
              records: [:],
              storage: nil,
              social: nil)
    }
    @discardableResult
    public func updateUserDomainProfile(for domain: DomainItem,
                                        request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile {
        .init(profile: .init(),
              messaging: .init(),
              socialAccounts: .init(),
              humanityCheck: .init(verified: false),
              records: [:],
              storage: nil,
              social: nil)
    }
    
    public func updatePendingDomainProfiles(with requests: [UpdateProfilePendingChangesRequest]) async throws {
        
    }
}

extension NetworkService: DomainProfileNetworkServiceProtocol {
    public func searchForDomainsWith(name: String,
                                     shouldBeSetAsRR: Bool) async throws -> [SearchDomainProfile] {
        var result = [SearchDomainProfile]()
        
        for i in 0..<40 {
            result.append(.init(name: "\(name)_\(i).x", ownerAddress: "123", imagePath: nil, imageType: nil))
        }
        
        return result
    }
    
    func isDomain(_ followerDomain: String, following followingDomain: String) async throws -> Bool {
        true
    }
    
    func fetchListOfFollowers(for domain: DomainName,
                              relationshipType: DomainProfileFollowerRelationshipType,
                              count: Int,
                              cursor: Int?) async throws -> DomainProfileFollowersResponse {
        .init(domain: domain,
              data: [],
              relationshipType: relationshipType,
              meta: .init(totalCount: 0, pagination: .init(cursor: nil, take: 1)))
    }
    
    func follow(_ domainNameToFollow: String, by domain: DomainItem) async throws {
   
    }
    
    func unfollow(_ domainNameToUnfollow: String, by domain: DomainItem) async throws {
       
    }
    
    func getProfileSuggestions(for domainName: DomainName) async throws -> SerializedDomainProfileSuggestionsResponse {
        MockEntitiesFabric.ProfileSuggestions.createSerializedSuggestionsForPreview()
    }
    
    func getTrendingDomains() async throws -> SerializedRankingDomainsResponse {
        MockEntitiesFabric.Explore.createTrendingProfiles()
    }
}

// MARK: - WalletTransactionsNetworkServiceProtocol
extension NetworkService: WalletTransactionsNetworkServiceProtocol {
    func getTransactionsFor(wallet: HexAddress,
                            cursor: String?,
                            chain: String?,
                            forceRefresh: Bool) async throws -> [WalletTransactionsPerChainResponse] {
        MockEntitiesFabric.WalletTxs.createMockTxsResponses()
    }
}

extension NetworkService {
    static let ipfsRedirectKey = "ipfs.html.value"

    struct SplitQuantity: Hashable {
        let doubleEth: Double
        let intEther: UInt64
        let gwei: UInt64
        let wei: UInt64
    }
    
    struct TxPayload {
        
    }
    
    
    struct ActionsPaymentInfo: Decodable {
        let id: String
        let clientSecret: String
        let totalAmount: UInt
    }
    
}

enum NetworkLayerError: LocalizedError, RawValueLocalizable {
    
    case creatingURLFailed
    case badResponseOrStatusCode(code: Int, message: String?)
    case parsingTxsError
    case responseFailedToParse
    case parsingDomainsError
    case authorizationError
    case noMessageError
    case invalidMessageError
    case noTxHashError
    case noBytesError
    case noNonceError
    case tooManyResponses
    case wrongNamingService
    case failedParseUnsRegistryAddress
    case failedToValidateResolver
    case failedParseProfileData
    case connectionLost
    case requestCancelled
    case notConnectedToInternet
    case failedFetchBalance
    case backendThrottle
    case failedToFindOwnerWallet
    case emptyParameters
    case invalidBlockchainAbbreviation
    case failedBuildSignRequest
    
    static let tooManyResponsesCode = -32005
    
    static func parse (errorResponse: ErrorResponseHolder) -> NetworkLayerError? {
        let error = errorResponse.error
        if error.code == tooManyResponsesCode {
            return .tooManyResponses
        }
        return nil
    }
    
    var rawValue: String {
        switch self {
        case .creatingURLFailed: return "creatingURLFailed"
        case .badResponseOrStatusCode(let code, let message): return "BadResponseOrStatusCode: \(code). \(message ?? "")"
        case .parsingTxsError: return "parsingTxsError"
        case .responseFailedToParse: return "responseFailedToParse"
        case .parsingDomainsError: return "Failed to get domains from server"
        case .authorizationError: return "The code is wrong or expired. Please retry"
        case .noMessageError: return "noMessageError"
        case .noTxHashError: return "noTxHashError"
        case .noBytesError: return "noBytesError"
        case .noNonceError: return "noNonceError"
        case .tooManyResponses: return "tooManyResponses"
        case .wrongNamingService: return "wrongNamingService"
        case .failedParseUnsRegistryAddress: return "failedParseUnsRegistryAddress"
        case .failedToValidateResolver: return "failedToValidateResolver"
        case .connectionLost: return "connectionLost"
        case .notConnectedToInternet: return "notConnectedToInternet"
        case .failedFetchBalance: return "failedFetchBalance"
        case .backendThrottle: return "backendThrottle"
        case .failedParseProfileData: return "failedParseProfileData"
        case .failedToFindOwnerWallet: return "failedToFindOwnerWallet"
        case .emptyParameters: return "emptyParameters"
        case .invalidMessageError: return "invalidMessageError"
        case .invalidBlockchainAbbreviation: return "invalidBlockchainAbbreviation"
        case .failedBuildSignRequest: return "failedBuildSignRequest"
        case .requestCancelled: return "requestCancelled"
        }
    }
    
    public var errorDescription: String? {
        return rawValue
    }
}
protocol ErrorResponseHolder {
    var error: ErrorResponse { set get }
}

struct ErrorResponse: Codable {
    var code: Int
    var message: String
}

struct MobileAPiErrorResponse: Decodable {
    let errors: [ErrorEntry]
}

struct GlobalRR: Codable {
    let address: String
    let name: String
    let avatarUrl: URL?
    let imageUrl: URL?
    
    var pfpURLToUse: URL? { imageUrl ?? avatarUrl }
}

struct ErrorEntry: Decodable {
    let code: String?
    let message: String?
    let field: String?
    let value: String?
    let status: Int?
}
