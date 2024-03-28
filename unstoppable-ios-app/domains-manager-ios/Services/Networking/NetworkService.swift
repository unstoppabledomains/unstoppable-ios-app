//
//  NetworkService.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 07.10.2020.
//

import Foundation

import Boilertalk_Web3
import Web3PromiseKit
import Web3ContractABI


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
    
    let infuraProjectId: String
    let startBlockNumber: String
    
    init() {
        self.infuraProjectId = Self.chooseInfuraProjectId()
        self.startBlockNumber = Self.chooseStartingBlockNumber()
    }
    
    static public func chooseInfuraProjectId() -> String {
        switch NetworkConfig.currentEnvironment {
        case .mainnet: return Self.mainnetInfuraProjectId
        case .testnet: return Self.testnetInfuraProjectId
        }
    }
    
    static public func chooseStartingBlockNumber() -> String {
        switch NetworkConfig.currentEnvironment {
        case .mainnet: return Self.startBlockNumberMainnet
        case .testnet: return Self.startBlockNumberMRinkeby
        }
    }
    
    static var authAPIKey: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return NetworkService.testnetMetadataAPIKey
        } else {
            return NetworkService.mainnetMetadataAPIKey
        }
    }
    
    static var authHeader: [String : String] {
        return ["Authorization" : "Bearer \(authAPIKey)"]
    }
    
    static var currentProfilesAPIKey: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return NetworkService.testnetProfilesAPIKey
        } else {
            return NetworkService.mainnetProfilesAPIKey
        }
    }
    
    static var profilesAPIHeader: [String : String] {
        ["x-api-key" : currentProfilesAPIKey]
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
    
    @discardableResult
    func fetchDataHandlingThrottleFor(endpoint: Endpoint,
                                      method: HttpRequestMethod) async throws -> Data {
        guard let url = endpoint.url else { throw NetworkLayerError.creatingURLFailed }
        let data = try await fetchDataHandlingThrottle(for: url, body: endpoint.body, method: method, extraHeaders: endpoint.headers)
        return data
    }
    
    func fetchDataHandlingThrottle(for url: URL,
                                   body: String? = nil,
                                   method: HttpRequestMethod = .post,
                                   extraHeaders: [String: String]  = [:]) async throws -> Data {
        let data: Data
        do {
            data = try await fetchData(for: url, body: body, method: method, extraHeaders: extraHeaders)
        } catch  {
            guard let err = error as? NetworkLayerError,
                  err == NetworkLayerError.backendThrottle else {
                throw error
            }
            try await Task.sleep(nanoseconds: 750_000_000)
            return try await fetchData(for: url, body: body, method: method, extraHeaders: extraHeaders) // allow another attempt in 0.75 sec
        }
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
                   body: String? = nil,
                   method: HttpRequestMethod = .post,
                   extraHeaders: [String: String]  = [:],
                   includeStandardJsonHeaders: Bool = true) async throws -> Data {
        let urlRequest = urlRequest(for: url,
                                    body: body,
                                    method: method,
                                    extraHeaders: extraHeaders,
                                    includeStandardJsonHeaders: includeStandardJsonHeaders)
        
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
    
    func isProfilePageExistsFor(domainName: String) async throws -> Bool {
        let link = String.Links.domainProfilePage(domainName: domainName)
        guard let url = link.url else { throw NetworkLayerError.creatingURLFailed }
        
        return try await withCheckedThrowingContinuation({ continuation in
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let response = response as? HTTPURLResponse {
                    let header = response.getHeader(for: "x-debug-service")
                    if header == nil {
                        Debugger.printFailure("Domain profile page has changed response structure", critical: true)
                    }
                    let isProfilePage = header == "ud.me"
                    continuation.resume(returning: isProfilePage)
                } else {
                    continuation.resume(throwing: error ?? NetworkLayerError.connectionLost)
                }
            }
            task.resume()
        })
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
                            body: String? = nil,
                            method: HttpRequestMethod = .post,
                            extraHeaders: [String: String]  = [:],
                            includeStandardJsonHeaders: Bool) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = method.string
        urlRequest.httpBody = body?.data(using: .utf8)
        
        if includeStandardJsonHeaders {
            Self.headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)}
        }
        
        extraHeaders.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)}
        urlRequest.addValue(Version.getCurrentAppVersionString() ?? "version n/a", forHTTPHeaderField: Self.appVersionHeaderKey)
        
        Debugger.printInfo(topic: .Network, "--- REQUEST TO ENDPOINT")
        Debugger.printInfo(topic: .Network, "METHOD: \(method) | URL: \(url.absoluteString)")
        Debugger.printInfo(topic: .Network, "BODY: \(body)")
        Debugger.printInfo(topic: .Network, "HEADERS: \(urlRequest.allHTTPHeaderFields ?? ["":""])")
        
        return urlRequest
    }
}

extension NetworkService {
    struct SplitQuantity: Hashable {
        let doubleEth: Double
        let intEther: UInt64
        let gwei: UInt64
        let wei: UInt64
        
        init(_ value: BigUInt) throws {
            self.doubleEth = Double(value).ethValue
            try self.intEther = UInt64(value / 1_000_000_000_000_000_000)
            try self.gwei = UInt64(value / 1_000_000_000)
            try self.wei = UInt64(value)
        }
    }
    
    func getJRPCProviderUrl(layerId: UnsConfigManager.BlockchainLayerId) -> URL {
        let netName: String
        switch layerId {
        case .l1: netName = NetworkConfig.currentNetNames.0
        case .l2: netName = NetworkConfig.currentNetNames.1
        }
        return URL(string: "https://\(netName).infura.io/v3/\(NetworkService.chooseInfuraProjectId())")!
    }
    
    func getJRPCProviderUrl(chainId: Int) -> URL? {
        guard let netName = BlockchainNetwork(rawValue: chainId)?.name else {
            return nil
        }
        return URL(string: "https://\(netName).infura.io/v3/\(NetworkService.chooseInfuraProjectId())")!
    }
    
    struct JRPCResponse: Decodable {
        let result: String
    }
    
    struct JRPCErrorResponse: Decodable {
        struct ErrorDescription: Decodable {
            let code: Int?
            let message: String?
        }
        let error: ErrorDescription
    }
    
    struct JRPCRequestInfo {
        let name: String
        let paramsBuilder: ()->String
    }
    
    enum JRPCError: Error {
        case failedBuildUrl
        case gasRequiredExceedsAllowance
        case genericError(String)
        case failedGetStatus
        case failedParseStatusPrices
        case unknownChain
        
        init(message: String) {
            if message.lowercased().starts(with: "gas required exceeds allowance") {
                self = .gasRequiredExceedsAllowance
            } else {
                self = .genericError(message)
            }
        }
    }
    
    func getJRPCRequest(chainId: Int,
                        requestInfo: JRPCRequestInfo) async throws -> String {
        
        guard let url = getJRPCProviderUrl(chainId: chainId) else {
            throw JRPCError.failedBuildUrl
        }
        let data = try await NetworkService().fetchData(for: url,
                                                        body: "{\"jsonrpc\":\"2.0\",\"method\":\"\(requestInfo.name)\",\"params\":\(requestInfo.paramsBuilder()),\"id\":1}",
                                                        method: .post)
        if let response = try? JSONDecoder().decode(JRPCResponse.self, from: data) {
            return response.result
        }
        
        if let response = try? JSONDecoder().decode(JRPCErrorResponse.self, from: data),
           let message = response.error.message {
            throw JRPCError(message: message)
        }
        
        throw JRPCError.genericError("Failed to parse \(String(data: data, encoding: .utf8) ?? "no data in response")")
    }
    
    func getTransactionCount(address: HexAddress,
                             chainId: Int) async throws -> String {
        
        try await getJRPCRequest(chainId: chainId,
                       requestInfo: JRPCRequestInfo(name: "eth_getTransactionCount",
                                                    paramsBuilder: { "[\"\(address)\", \"latest\"]"} ))
    }
    
    func getGasEstimation(tx: EthereumTransaction,
                          chainId: Int) async throws -> String {
        
        try await getJRPCRequest(chainId: chainId,
                       requestInfo: JRPCRequestInfo(name: "eth_estimateGas",
                                                    paramsBuilder: { "[\(tx.parameters), \"latest\"]"} ))
    }
    
    func getGasPrice(chainId: Int) async throws -> String {
        try await getJRPCRequest(chainId: chainId,
                       requestInfo: JRPCRequestInfo(name: "eth_gasPrice",
                                                    paramsBuilder: { "[]"} ))
    }
    
    func getStatusGasPrices(env: UnsConfigManager.BlockchainEnvironment) async throws -> [String: [String: Int]]{
        let url = env == .mainnet ? URL(string: "https://api.unstoppabledomains.com/api/v1/status")! :
                                    URL(string: "https://api.ud-staging.com/api/v1/status")!
        let data = try await NetworkService().fetchData(for: url, method: .get)
        
        guard let jsonPrices = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let eth = jsonPrices["ETH"] as? [String: Any],
              let ethPrices = eth["averageGasPrices"] as? [String: Int],
              let matic = jsonPrices["MATIC"] as? [String: Any],
              let maticPrices = matic["averageGasPrices"] as? [String: Int] else {
                 throw JRPCError.failedGetStatus
             }
        return ["ETH": ethPrices, "MATIC": maticPrices]
    }
    
    func fetchGasPrice(chainId: Int, for speed: CryptoSendingSpec.TxSpeed) async throws -> Int {
        let prices = try await getStatusGasPrices(chainId: chainId)
        switch speed {
        case .normal: return prices["safeLow"]!
        case .fast: return prices["fast"]!
        case .urgent: return prices["fastest"]!
        }
    }
    
    func getStatusGasPrices(chainId: Int) async throws -> [String: Int] {
        switch chainId {
        case BlockchainNetwork.ethMainnet.rawValue: return try await getStatusGasPrices(env: .mainnet)["ETH"]!
        case BlockchainNetwork.polygonMainnet.rawValue: return try await getStatusGasPrices(env: .mainnet)["MATIC"]!
        case BlockchainNetwork.ethGoerli.rawValue: return try await getStatusGasPrices(env: .testnet)["ETH"]!
        case BlockchainNetwork.ethSepolia.rawValue: return try await getStatusGasPrices(env: .testnet)["ETH"]!
        case BlockchainNetwork.polygonMumbai.rawValue: return try await getStatusGasPrices(env: .testnet)["MATIC"]!
        default: throw JRPCError.unknownChain
        }
    }
}

extension NetworkService {
    static let ipfsRedirectKey = "ipfs.html.value"
    struct ResolveDomainsApiResponse: Decodable {
        typealias RecordsArray = [String: String]
        struct MetaData: Decodable {
            let domain: String?
            let resolver: String?
            let owner: String?
        }
        
        let meta: MetaData
        let records: RecordsArray
    }
    
    func fetchReverseResolution(for address: HexAddress) async throws -> DomainName? {
        let url = URL(string: "\(NetworkConfig.baseResolveUrl)/reverse/\(address)")!
        let data = try await NetworkService().fetchData(for: url,
                                                        method: .get,
                                                        extraHeaders: NetworkService.authHeader)
        let response = try JSONDecoder().decode(ResolveDomainsApiResponse.self, from: data)
        return response.meta.domain
    }
    
    /// This function will return UD/ENS/Null name and corresponding PFP if available OR throw 404
    func fetchGlobalReverseResolution(for identifier: HexAddress) async throws -> GlobalRR? {
        do {
            guard let url = URL(string: "\(NetworkConfig.baseProfileUrl)/profile/resolve/\(identifier)") else { return nil } // User's input contains not allowed characters
            
            let data = try await NetworkService().fetchData(for: url,
                                                            method: .get)
            let response = try JSONDecoder().decode(GlobalRR.self, from: data)
            return response
        } catch NetworkLayerError.badResponseOrStatusCode(let code, _) where code == 404 { // 404 means no RR domain or ENS domain
            return nil
        } catch {
            throw error
        }
    }
    
    private func getRegex(for expandedTicker: String, coins: [CoinRecord]) -> String? {
        coins.first(where: {$0.expandedTicker == expandedTicker})?.regexPattern
    }
    
    static func getRequestForActionSign(id: UInt64,
                                        response: NetworkService.ActionsResponse,
                                        signatures: [String]) throws -> APIRequest {
        let request = try APIRequestBuilder()
            .actionSign(for: id, response: response, signatures: signatures)
            .build()
        return request
    }
}

extension EthereumTransaction {
    var parameters: String {
        var object: [String: String] = [:]
        if let from = self.from {
            object["from"] = from.hex()
        }
        if let to = self.to {
            object["to"] = to.hex()
        }
        if let gasPrice = self.gasPrice {
            object["gasPrice"] = gasPrice.hex()
        }
        if let value = self.value {
            object["value"] = value.hex()
        }
        object["data"] = data.hex()
        
        let data = (try? JSONEncoder().encode(object)) ?? Data()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

protocol ErrorResponseHolder {
    var error: ErrorResponse { set get }
}

struct ErrorResponse: Codable {
    var code: Int
    var message: String
}

enum NetworkLayerError: LocalizedError, RawValueLocalizable, Comparable {
    static func < (lhs: NetworkLayerError, rhs: NetworkLayerError) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
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
    case domainHasNullRecordValue
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
        case .badResponseOrStatusCode(let code, let message): return "BadResponseOrStatusCode: \(code) - \(message ?? "-||-")"
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
        case .domainHasNullRecordValue: return "domainHasNullRecordValue"
        }
    }
    
    public var errorDescription: String? {
        return rawValue
    }
}

struct ResponseLog: Codable {
    public var topics: [HexAddress]
    public var data: String
    
    init(_ log: EthereumLogObject) {
        var tops: [HexAddress] = []
        log.topics.forEach {
            tops.append($0.hex())
        }
        self.topics = tops
        self.data = log.data.hex()
    }
}

extension EthereumAddress {
    public func hex() -> String {
        self.hex(eip55: true)
    }
}


extension HTTPURLResponse {
    func getAllHeaders() {
        let headers = self.allHeaderFields as? [String: String]
    }
    
    func getHeader(for key: String) -> String? {
        self.value(forHTTPHeaderField: key)
    }
}
