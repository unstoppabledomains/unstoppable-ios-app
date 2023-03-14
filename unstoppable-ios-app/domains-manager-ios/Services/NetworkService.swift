//
//  NetworkService.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 07.10.2020.
//

import Foundation

import Web3
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
    
    func fetchData(for url: URL,
                   body: String = "",
                   method: HttpRequestMethod = .post,
                   extraHeaders: [String: String]  = [:],
                   completionHandler: @escaping (Result<Data>)->Void) {
        let urlRequest = urlRequest(for: url, body: body, method: method, extraHeaders: extraHeaders)
        
        URLSession.shared.dataTask(
            with: urlRequest,
            completionHandler: { (taskData: Data?, response: URLResponse?, taskError: Error?) in
                if let response = response as? HTTPURLResponse {
                    if Self.httpSuccessRange.contains(response.statusCode) {
                        completionHandler(.fulfilled(taskData ?? Data()))
                    } else {
                        if response.statusCode == Constants.backEndThrottleErrorCode {
                            Debugger.printWarning("Request failed due to backend throttling issue")
                            completionHandler(.rejected(NetworkLayerError.backendThrottle))
                        } else {
                            let message = extractErrorMessage(from: taskData)
                            completionHandler(.rejected(NetworkLayerError.badResponseOrStatusCode(code: response.statusCode, message: "\(message)")))
                        }
                    }
                } else {
                    Debugger.printFailure("Error accessing url: \(url), status code = \(String(describing: (response as? HTTPURLResponse)?.statusCode)), error: \(String(describing: taskError))", critical: NetworkService.DebugOptions.shouldCrashIfBadResponse)
                    completionHandler(.rejected(taskError ?? NetworkLayerError.badResponseOrStatusCode(code: 0, message: "No Http response")))
                }
            }
        ).resume()
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
                case NSURLErrorNetworkConnectionLost, NSURLErrorCancelled:
                    throw NetworkLayerError.connectionLost
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
            return try await withSafeCheckedThrowingContinuation { completion in
                fetchData(for: url,
                          body: body,
                          method: method,
                          extraHeaders: extraHeaders) { result in
                    switch result {
                    case .fulfilled(let data):
                        return completion(.success(data))
                    case .rejected(let error):
                        return completion(.failure(error))
                    }
                }
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
        
        guard Debugger.shouldLogHeapAnalytics || !url.absoluteString.contains("heap") else { return urlRequest }
        
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
        guard let netName = UnsConfigManager.blockchainNamesMap[chainId] else { return nil }
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
        try await withSafeCheckedThrowingContinuation({ completion in
            let start = Date()
            fetchBalance(address: address, layerId: layerId) { quantity in
                Debugger.printInfo("\(String.itTook(from: start)) to load balance for layer \(layerId)")
                guard let quantity = quantity else {
                    completion(.failure(NetworkLayerError.failedFetchBalance))
                    return
                }

                completion(.success(quantity))
            }
        })
    }
    
    func fetchBalance (address: HexAddress,
                        layerId: UnsConfigManager.BlockchainLayerId,
                        callback: @escaping (SplitQuantity?)->Void) {
        
        NetworkService().fetchData(for: getJRPCProviderUrl(layerId: layerId),
                                   body: "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\": [\"\(address)\", \"latest\"],\"id\":1}",
                                   method: .post) {
            switch $0 {
            case .fulfilled (let data): guard let response = try? JSONDecoder().decode(JRPCResponse.self, from: data) else {
                callback(nil)
                return
            }
                let bigUInt = BigUInt(response.result.dropFirst(2), radix: 16) ?? 0
                callback(try? SplitQuantity(bigUInt))
                return
            case .rejected: callback(nil)
            }
        }
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
                        requestInfo: JRPCRequestInfo,
                        callback: @escaping (Result<String>)->Void) {
        
        guard let url = getJRPCProviderUrl(chainId: chainId) else {
            callback(.rejected(JRPCError.failedBuildUrl))
            return
        }
        NetworkService().fetchData(for: url,
                                   body: "{\"jsonrpc\":\"2.0\",\"method\":\"\(requestInfo.name)\",\"params\":\(requestInfo.paramsBuilder()),\"id\":1}",
                                   method: .post) {
            switch $0 {
            case .fulfilled (let data):
                
                if let response = try? JSONDecoder().decode(JRPCResponse.self, from: data) {
                    callback(.fulfilled(response.result))
                    return
                }
                
                if let response = try? JSONDecoder().decode(JRPCErrorResponse.self, from: data),
                   let message = response.error.message {
                    callback(.rejected(JRPCError(message: message)))
                    return
                }
                
                callback(.rejected(JRPCError.genericError("Failed to parse \(String(data: data, encoding: .utf8) ?? "no data in response")")))
                return
                
            case .rejected(let error): callback(.rejected(JRPCError.genericError(error.localizedDescription)))
            }
        }
    }
    
    func getJRPCRequest(chainId: Int,
                        requestInfo: JRPCRequestInfo,
                        callback: @escaping (String?)->Void) {
        getJRPCRequest(chainId: chainId, requestInfo: requestInfo) { (result: Result<String>) in
            switch result {
            case .fulfilled(let s): callback(s)
            case .rejected: callback(nil)
            }
        }
    }
    
    func getTransactionCount(address: HexAddress,
                             chainId: Int,
                             callback: @escaping (String?)->Void) {
        
        getJRPCRequest(chainId: chainId,
                       requestInfo: JRPCRequestInfo(name: "eth_getTransactionCount",
                                                    paramsBuilder: { "[\"\(address)\", \"latest\"]"} ),
                       callback: callback)
    }
    
    func getGasEstimation(tx: EthereumTransaction,
                          chainId: Int,
                          callback: @escaping (Result<String>)->Void) {
        
        getJRPCRequest(chainId: chainId,
                       requestInfo: JRPCRequestInfo(name: "eth_estimateGas",
                                                    paramsBuilder: { "[\(tx.parameters), \"latest\"]"} ),
                       callback: callback)
    }
    
    func getGasPrice(chainId: Int,
                     callback: @escaping (String?)->Void) {
        getJRPCRequest(chainId: chainId,
                       requestInfo: JRPCRequestInfo(name: "eth_gasPrice",
                                                    paramsBuilder: { "[]"} ),
                       callback: callback)
    }
}

extension NetworkService {
    static let ipfsRedirectKey = "ipfs.html.value"
    struct ResolveDomainsApiResponse: Decodable {
        typealias RecordsArray = [String: String]
        struct MetaData: Decodable {
            let domain: String?
            let resolver: String?
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
