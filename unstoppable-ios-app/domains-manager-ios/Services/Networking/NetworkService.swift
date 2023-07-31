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
    
    func fetchData(for url: URL,
                   body: String = "",
                   method: HttpRequestMethod = .post,
                   extraHeaders: [String: String]  = [:]) async throws -> Data {
        let urlRequest = urlRequest(for: url, body: body, method: method, extraHeaders: extraHeaders)
        
        if #available(iOS 15.0, *) {
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
        } else {
            return try await fetchData(for: url,
                                       body: body,
                                       method: method,
                                       extraHeaders: extraHeaders)
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
        Debugger.printInfo(topic: .Network, "HEADERS: \(urlRequest.headers)")
        
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
        guard let netName = BlockchainNetwork(rawValue: chainId)?.name else { return nil }
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
    
    func fetchBalance (address: HexAddress,
                       layerId: UnsConfigManager.BlockchainLayerId) async throws -> SplitQuantity {
        
        
        guard let data = try? await NetworkService().fetchData(for: getJRPCProviderUrl(layerId: layerId),
                                                               body: "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\": [\"\(address)\", \"latest\"],\"id\":1}",
                                                               method: .post),
              let response = try? JSONDecoder().decode(JRPCResponse.self, from: data) else {
            throw NetworkLayerError.failedFetchBalance
        }
        let bigUInt = BigUInt(response.result.dropFirst(2), radix: 16) ?? 0
        return try SplitQuantity(bigUInt)
    }
    
    
    struct JRPCRequestInfo {
        let name: String
        let paramsBuilder: ()->String
    }
    
    enum JRPCError: Error {
        case failedBuildUrl
        case gasRequiredExceedsAllowance
        case genericError(String)
        
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
    
    func fetchRecords (domain: DomainItem) async throws -> DomainRecordsData {
        let url = URL(string: "\(NetworkConfig.baseResolveUrl)/domains/\(domain.name)")!
        let data = try await NetworkService().fetchData(for: url,
                                                        method: .get,
                                                        extraHeaders: MetadataNetworkConfig.authHeader)
        let response = try JSONDecoder().decode(ResolveDomainsApiResponse.self, from: data)
        let resolver = response.meta.resolver
        
        let records = response.records
        let coinRecords = await appContext.coinRecordsService.getCurrencies()
        
        return DomainRecordsData(from: records,
                                 coinRecords: coinRecords,
                                 resolver: resolver)
    }
    
    func fetchReverseResolution(for address: HexAddress) async throws -> DomainName? {
        let url = URL(string: "\(NetworkConfig.baseResolveUrl)/reverse/\(address)")!
        let data = try await NetworkService().fetchData(for: url,
                                                        method: .get,
                                                        extraHeaders: MetadataNetworkConfig.authHeader)
        let response = try JSONDecoder().decode(ResolveDomainsApiResponse.self, from: data)
        return response.meta.domain
    }
    
    func fetchDomainOwner(for domainName: DomainName) async throws -> HexAddress? {
        let url = URL(string: "\(NetworkConfig.baseResolveUrl)/domains/\(domainName)")!
        let data = try await NetworkService().fetchData(for: url,
                                                        method: .get,
                                                        extraHeaders: MetadataNetworkConfig.authHeader)
        let response = try JSONDecoder().decode(ResolveDomainsApiResponse.self, from: data)
        return response.meta.owner
    }
    
    struct GlobalRR: Codable {
        let address: String
        let name: String?
        let avatarUrl: URL?
    }
    
    /// This function will return UD/ENS/Null name and corresponding PFP if available OR throw 404
    func fetchGlobalReverseResolution(for address: HexAddress) async throws -> GlobalRR {
//        let url = URL(string: "\(NetworkConfig.baseResolveUrl)/profile/resolve/\(address)")!
        let url = URL(string: "https://api.ud-staging.com/profile/resolve/\(address)")! // Works only in staging ATM
        let data = try await NetworkService().fetchData(for: url,
                                                        method: .get,
                                                        extraHeaders: MetadataNetworkConfig.authHeader)
        let response = try JSONDecoder().decode(GlobalRR.self, from: data)
        return response
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
        case .badResponseOrStatusCode(let code): return "BadResponseOrStatusCode: \(code)"
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
