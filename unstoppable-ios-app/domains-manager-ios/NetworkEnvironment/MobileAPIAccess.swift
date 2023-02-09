//
//  MobileAPIAccess.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.12.2020.
//

import Foundation
import PromiseKit

protocol TxsFetcher {
    func fetchAllTxs(for domains: [String]) -> Promise<[TransactionItem]>
    func fetchAllTxs(for domains: [String]) async throws -> [TransactionItem]
}

extension NetworkService: TxsFetcher {
    public func fetchAllTxs(for domains: [String]) -> Promise<[TransactionItem]> {
        fetchAllPagesWithLimit(for: domains, limit: Self.postRequestLimit)
    }
    
    public func fetchAllTxs(for domains: [String]) async throws -> [TransactionItem] {
        try await fetchAllPagesWithLimit(for: domains, limit: Self.postRequestLimit)
    }
}

extension NetworkService {
    static var isBackendSimulated: Bool { false }
    
    public func requestSecurityCode (for email: String, operation: DeepLinkOperation) -> Promise<Void> {
        return Promise { seal in
            guard let request = try? APIRequestBuilder().users(email: email)
                    .operation(operation)
                    .authenticate()
                    .build() else {
                Debugger.printFailure("Couldnt build url", critical: true)
                return
            }
            fetchData(for: request.url, body: request.body, extraHeaders: request.headers) { result in
                switch result {
                case .fulfilled( _): seal.fulfill(())
                case .rejected(let error): seal.reject(error)
                }
            }
        }
    }
    
    func updatePushNotificationsInfo(info: PushNotificationsInfo) async throws {
        guard let request = try? APIRequestBuilder()
            .apnsTokens(info: info)
            .build() else {
            Debugger.printFailure("Couldnt build url", critical: true)
            return
        }
         
        _ = try await fetchData(for: request.url, body: request.body, extraHeaders: request.headers)
    }
    
    func subscribePushNotificationsForWCDApp(info: WalletConnectPushNotificationsSubscribeInfo) async throws {
        guard let request = try? APIRequestBuilder()
            .wcPushNotificationsSubscribe(info: info)
            .build() else {
            Debugger.printFailure("Couldnt build url", critical: true)
            return
        }
        
        _ = try await fetchData(for: request.url, body: request.body, extraHeaders: request.headers)
    }
    
    func unsubscribePushNotificationsForWCDApp(info: WalletConnectPushNotificationsUnsubscribeInfo) async throws {
        guard let request = try? APIRequestBuilder()
            .wcPushNotificationsUnsubscribe(info: info)
            .build() else {
            Debugger.printFailure("Couldnt build url", critical: true)
            return
        }
        
        _ = try await fetchData(for: request.url, body: request.body, extraHeaders: request.headers)
    }
    
    // Response
    struct TxResponseArray: Codable {
        @IgnoreFailureArrayElement
        var txs: [TxResponse]
    }
    
    struct TxResponse: Codable {
        let id: UInt64
        let type: TxType
        let operation: TxOperation
        let statusGroup: String
        let hash: String?
        let domain: TxDomainResponse
//        let cryptoWallet: TxCryptoWalletResponse
        
    }
    
    struct TxDomainResponse: Codable {
        let id: Int
        let name: String
        let ownerAddress: String?
    }
    
    struct WalletArrayResponse: Codable {
        let wallets: [TxCryptoWalletResponse]
    }
    
    struct TxCryptoWalletResponse: Codable {
        let id: Int
        let blockchain: String
        let publicKey: String?
        let address: String
        let verified: Bool
        let humanAddress: String
        
        func getNamingService() -> NamingService? {
            guard let blockchain = try? BlockchainType.getType(abbreviation: self.blockchain) else {
                return nil
            }
            
            switch blockchain {
            case .Ethereum, .Matic: return .UNS
            case .Zilliqa: return .ZNS
            }
        }
    }
    
    struct DomainsInfo {
        let domainNames: [String]
        let txCosts: [TxCost]?
    }
    
    // Response
    struct DomainResponseArray: Decodable {
        let domains: [DomainResponse]
        let txCosts: [TxCost]?
    }
    
    struct DomainResponse: Decodable {
        let id: Int
        let name: String
        let ownerAddress: String?
        let resolver: String?
        let blockchain: String?
        let networkId: Int?
        let resolution: DomainResponseResolution?
    }
    
    struct DomainResponseResolution: Decodable {
        let imageValue: String?
        
        enum CodingKeys: String, CodingKey {
            case imageValue = "social.picture.value"
        }
    }
    
    struct MobileAPiErrorResponse: Decodable {
        let errors: [ErrorEntry]
    }
    
    struct ErrorEntry: Decodable {
        let code: String?
        let message: String?
        let field: String?
        let value: String?
        let status: Int?
    }
    
    struct TxCostContainer: Codable {
        let txCost: TxCost
    }
    
    struct TxCost: Codable {
        let quantity: Int
        let stripeIntent: String
        let stripeSecret: String
        let gasPrice: UInt64
        let gasLimit: UInt64
        let usdToEth: UInt64
        let fee: Int
        let price: Int
    }
    
    struct TxData: Codable {
        let message: String?
        let bytes: Buffer?
        let nonce: UInt?
        let blockchain: String
    }
    
    struct DomainData: Codable {
        let name: String
        let blockchain: String
        let node: String
    }
    
    struct CombinedMessagesToSignResponse: Codable {
        let txs: [TxData]
        let domain: DomainData
        let txCost: TxCost?
    }
    
    struct Buffer: Codable {
        let type: String
        let data: [UInt8]
    }
    
    struct TxPayload {
        let messages: [String]
        let txCost: TxCost?
        
        init(messages: [String], txCost: TxCost?) {
            self.txCost = txCost
            self.messages = messages
        }
        
        init(txCost: TxCost?) {
            self.txCost = txCost
            self.messages = []
        }
        
        func getTxCost() -> NetworkService.TxCost {
            guard let txCost = self.txCost else {
                Debugger.printFailure("No txCost", critical: true)
                return NetworkService.TxCost(quantity: 0, stripeIntent: "", stripeSecret: "", gasPrice: 0, gasLimit: 0, usdToEth: 0, fee: 0, price: 0)
            }
            return txCost
        }
    }
    
    private func unfoldArray<T> (_ array: [Result<T>]) -> Promise<[T]>{
        return Promise { seal in
            let result: [T] = array.reduce([], { res, el in
                var arrCopy = res
                
                switch el {
                case .fulfilled(let element): arrCopy.append(element)
                case .rejected(let error): seal.reject(error)
                }
                return arrCopy
            })
            seal.fulfill(result)
        }
    }
    
    public func getAllUnmintedDomains(for email: String, withAccessCode code: String) -> Promise<DomainsInfo> {
        guard let request = try? APIRequestBuilder()
                                    .users(email: email)
                                    .secure(code: code)
                                    .fetchAllUnMintedDomains()
                                    .build() else {
            Debugger.printFailure("Couldn't build the url", critical: true)
            return Promise() { seal in seal.reject(NetworkLayerError.creatingURLFailed)}
        }
        return getUnmintedDomainsListPromise(for: email,
                                                     withAccessCode: code,
                                                     request: request)
    }

    public func getUnmintedDomainsListPromise(for email: String,
                                                      withAccessCode code: String,
                                                      request: APIRequest) -> Promise<DomainsInfo> {
        return Promise { seal in
            fetchData(for: request.url,
                         method: .get,
                      extraHeaders: request.headers) { result in
                switch result {
                case .fulfilled(let data):
                    if let response = try? JSONDecoder().decode(DomainResponseArray.self, from: data) {
                        let info = DomainsInfo(domainNames: response.domains.map({$0.name}),
                                            txCosts: response.txCosts)
                        seal.fulfill(info)
                        return
                    }
                    if let _ = try? JSONDecoder().decode(MobileAPiErrorResponse.self, from: data) {
                        seal.reject(NetworkLayerError.authorizationError)
                        return
                    } else {
                        seal.reject(NetworkLayerError.parsingDomainsError)
                    }
                case .rejected(let error): seal.reject(error)
                }
            }
        }
    }

    public func mint(domains: [DomainItem],
                      with email: String,
                      code: String,
                      stripeIntent: String?) -> Promise<[TransactionItem]> {
        return Promise { seal in
            guard let request = try? APIRequestBuilder().users(email: email)
                                                        .secure(code: code)
                                                        .mint(domains, stripeIntent: stripeIntent)
                                                        .build() else {
                Debugger.printFailure("Couldn't build the mint request", critical: true)
                seal.reject(NetworkLayerError.creatingURLFailed)
                return
            }
            fetchData(for: request.url,
                      body: request.body,
                      extraHeaders: request.headers) { result in
                switch result {
                case .fulfilled(let data):
                    if let array = try? JSONDecoder().decode(TxResponseArray.self, from: data) {
                        let txArray: [TransactionItem] = array.txs.compactMap({ TransactionItem(jsonResponse: $0) })
                        seal.fulfill(txArray)
                    } else {
                        seal.reject(NetworkLayerError.parsingTxsError)
                    }
                case .rejected(let error): seal.reject(error)
                }
            }
        }
    }
}

extension NetworkService {
    static let postRequestLimit = 500
 
    public func fetchUnsDomains(for wallets: [UDWallet]) -> Promise<[DomainItem]> {
        let ownerUnsAddresses = wallets.compactMap({ $0.extractEthWallet()?.address.normalized})
        guard !ownerUnsAddresses.isEmpty else { return Promise { $0.fulfill([]) } }
        return fetchDomains(for: ownerUnsAddresses)
    }
    
    public func fetchUnsDomains(for wallets: [UDWallet]) async throws -> [DomainItem] {
        let ownerUnsAddresses = wallets.compactMap({ $0.extractEthWallet()?.address.normalized})
        guard !ownerUnsAddresses.isEmpty else { return [] }
        return try await fetchDomains(for: ownerUnsAddresses)
    }
    
    public func fetchZilDomains(for wallets: [UDWallet]) -> Promise<[DomainItem]> {
        let ownerZilAddresses = wallets.compactMap({ $0.extractZilWallet()?.address.normalized})
        guard !ownerZilAddresses.isEmpty else { return Promise { $0.fulfill([]) } }
        return fetchDomains(for: ownerZilAddresses)
    }
    
    public func fetchZilDomains(for wallets: [UDWallet]) async throws -> [DomainItem] {
        let ownerZilAddresses = wallets.compactMap({ $0.extractZilWallet()?.address.normalized})
        guard !ownerZilAddresses.isEmpty else { return [] }
        return try await fetchDomains(for: ownerZilAddresses)
    }
    
    private func fetchDomains(for ownerAddresses: [HexAddress]) -> Promise<[DomainItem]> {
        fetchAllPagesWithLimit(for: ownerAddresses, limit: Self.postRequestLimit)
    }
    
    private func fetchDomains(for ownerAddresses: [HexAddress]) async throws -> [DomainItem] {
        try await fetchAllPagesWithLimit(for: ownerAddresses, limit: Self.postRequestLimit)
    }

    func fetchAllPagesWithLimit<T: PaginatedFetchable>(for originItems: [T.O], limit: Int) -> Promise<[T]> {
        var items = originItems
        var promiseArray: [Promise<[T]>] = []
        while items.count > 0 {
            let batch = items.prefix(limit)
            items = Array(items.dropFirst(batch.count))
            promiseArray.append(fetchAllPages(for: Array(batch)))
        }
        return Promise { seal in
            when(fulfilled: promiseArray)
                .done { t in
                    seal.fulfill(t.flatMap({ $0 }))
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
    func fetchAllPagesWithLimit<T: PaginatedFetchable>(for originItems: [T.O], limit: Int) async throws -> [T] {
        guard !originItems.isEmpty else { return [] }
        
        let loader = PaginatedFetchableBatchLoader<T>(maxOperations: Constants.maximumConcurrentNetworkRequestsLimit)
        let response = try await withSafeCheckedThrowingContinuation({ completion in
            loader.fetchAllPagesWithLimit(for: originItems, limit: limit, resultBlock: { result in
                switch result {
                case .success(let result):
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        })
        
        return response
    }
    
    func fetchAllPages<T: PaginatedFetchable>(for originItems: [T.O]) -> Promise<[T]> {
        typealias GenericState = (page: Int, items: [T], lastBatchPicked: Bool)
        
        return Promise { seal in
            let perPage = 1000
            let state: GenericState = (page: 1, items: [], lastBatchPicked: false)
            var error: Error?
            
            var s = sequence(state: state, next: { ( state: inout GenericState) -> [T]? in
                if state.lastBatchPicked { return nil }
                let nextFetch = T.fetchPaginatedData_Blocking(for: originItems,
                                                                    page: state.page,
                                                                    perPage: perPage)
                switch  nextFetch {
                case .fulfilled(let itemsBatch):
                    if itemsBatch.count == 0 { return nil }
                    if itemsBatch.count < perPage { state.lastBatchPicked = true }
                    state.items.append(contentsOf: itemsBatch)
                    state.page = state.page + 1
                    return state.items
                    
                case .rejected(let loadingError):
                    error = loadingError
                    return nil
                }
            })
          
            
            var result: [T] = []
            var reading = true
            repeat {
                guard let next = s.next() else {
                    reading = false
                    continue
                }
                result += next
            } while (reading)
            
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill(result)
            }
        }
    }
    
    func fetchAllPages<T: PaginatedFetchable>(for originItems: [T.O]) async throws -> [T] {
        let perPage = 1000
        let result: [T] = try await fetchAllPages(for: originItems, startingWith: 1, perPage: perPage, result: [])
        
        return result
    }
    
    func fetchAllPages<T: PaginatedFetchable>(for originItems: [T.O], startingWith page: Int, perPage: Int, result: [T]) async throws -> [T] {
        let itemsBatch: [T] = try await fetchPage(for: originItems, page: page, perPage: perPage)
        var result = result
        result.append(contentsOf: itemsBatch)
        
        if itemsBatch.count < perPage {
            return result
        } else {
            let nextPage = page + 1
            return try await fetchAllPages(for: originItems, startingWith: nextPage, perPage: perPage, result: result)
        }
    }
    
    func fetchPage<T: PaginatedFetchable>(for originItems: [T.O], page: Int, perPage: Int) async throws -> [T] {
        let itemsBatch = try await T.fetchPaginatedData_Blocking(for: originItems,
                                                                 page: page,
                                                                 perPage: perPage)
        
        return itemsBatch
    }
        
    static func gen_paginatedBlockingFetchDataGen<T: PaginatedFetchable>(for originItems: [T.O],
                                                  page: Int,
                                                  perPage: Int) -> Result<[T]> {
        guard originItems.count > 0 else { return Result.fulfilled([]) }
        
        let semaphor = DispatchSemaphore(value: 0)
        var outcome: Result<[T]>!
        
        let request: APIRequest
        do {
            request = try T.createRequestForPaginated(for: originItems, page: page, perPage: perPage)
        } catch {
            return Result.rejected(error)
        }
        NetworkService().fetchData(for: request.url,
                                   body: request.body,
                                   method: request.method,
                                   extraHeaders: request.headers) { result in
            switch result {
            case .fulfilled(let data):
                if let json = try? JSONDecoder().decode(T.J.self, from: data) {
                    outcome = Result.fulfilled(T.convert(json))
                } else {
                    outcome = Result.rejected(NetworkLayerError.parsingDomainsError)
                }
            case .rejected(let error):  outcome = Result.rejected(error)
            }
            semaphor.signal()
        }
        semaphor.wait()
        return outcome
    }
    
    static func gen_paginatedBlockingFetchDataGen<T: PaginatedFetchable>(for originItems: [T.O],
                                                                         page: Int,
                                                                         perPage: Int) async throws -> [T] {
        guard originItems.count > 0 else { return [] }
        
        let request: APIRequest = try T.createRequestForPaginated(for: originItems, page: page, perPage: perPage)
        let data = try await NetworkService().fetchData(for: request.url,
                                                        body: request.body,
                                                        method: request.method,
                                                        extraHeaders: request.headers)
        
        if let json = try? JSONDecoder().decode(T.J.self, from: data) {
            return T.convert(json)
        } else {
            throw NetworkLayerError.parsingDomainsError
        }
    }
}

protocol PaginatedFetchable {
    associatedtype O
    associatedtype J: Decodable
    associatedtype D
    
    init(jsonResponse: D)
    static func convert(_ json: Self.J) -> [Self]

    static func createRequestForPaginated(for originItems: [O],
                               page: Int,
                               perPage: Int) throws -> APIRequest
    
    static func fetchPaginatedData_Blocking(for originItems: [O],
                                               page: Int,
                                               perPage: Int) -> Result<[Self]>
    static func fetchPaginatedData_Blocking(for originItems: [O],
                                            page: Int,
                                            perPage: Int) async throws -> [Self] 
   
}

extension PaginatedFetchable {
    static func fetchPaginatedData_Blocking(for originItems: [O],
                                            page: Int,
                                            perPage: Int) async throws -> [Self] { [] }
}

enum FetchRequestBuilderError: String, LocalizedError {
    case domains
    case txs
    
    public var errorDescription: String? {
        return rawValue
    }
}

extension DomainItem: PaginatedFetchable {
    typealias O = HexAddress
    typealias J = NetworkService.DomainResponseArray
    typealias D = NetworkService.DomainResponse
    
    static func convert(_ json: Self.J) -> [Self] {
        json.domains.compactMap({Self.init(jsonResponse: $0)})
    }
    
    static func createRequestForPaginated(for originItems: [HexAddress],
                                          page: Int,
                                          perPage: Int) throws -> APIRequest {
        guard let endpoint = Endpoint.domainsByOwnerAddressesPost(owners: originItems,
                                                                  page: page,
                                                                  perPage: perPage) else {
            throw FetchRequestBuilderError.domains
        }
        return APIRequest(url: endpoint.url!, body: endpoint.body, method: .post)
    }
    
    static func fetchPaginatedData_Blocking(for addresses: [HexAddress],
                                            page: Int,
                                            perPage: Int) -> Result<[DomainItem]> {
        return NetworkService.gen_paginatedBlockingFetchDataGen(for: addresses, page: page, perPage: perPage)
    }
    
    static func fetchPaginatedData_Blocking(for originItems: [O],
                                            page: Int,
                                            perPage: Int) async throws -> [Self] {
        try await NetworkService.gen_paginatedBlockingFetchDataGen(for: originItems, page: page, perPage: perPage)
    }
}

extension TransactionItem: PaginatedFetchable {
    typealias O = String
    typealias J = NetworkService.TxResponseArray
    typealias D = NetworkService.TxResponse
    
    static func convert(_ json: Self.J) -> [Self] {
        json.txs.compactMap({Self.init(jsonResponse: $0)})
    }
    
    static func createRequestForPaginated(for originItems: [O],
                                          page: Int,
                                          perPage: Int) throws -> APIRequest {
        guard let endpoint = Endpoint.transactionsByDomainsPost(domains: originItems,
                                                                page: page,
                                                                perPage: perPage) else {
            throw FetchRequestBuilderError.txs
        }
        return APIRequest(url: endpoint.url!, body: endpoint.body, method: .post)
    }
    
    static func fetchPaginatedData_Blocking(for domains: [O],
                                               page: Int,
                                               perPage: Int) -> Result<[TransactionItem]> {
        return NetworkService.gen_paginatedBlockingFetchDataGen(for: domains, page: page, perPage: perPage)
    }
    
    static func fetchPaginatedData_Blocking(for originItems: [O],
                                            page: Int,
                                            perPage: Int) async throws -> [Self] {
        try await NetworkService.gen_paginatedBlockingFetchDataGen(for: originItems, page: page, perPage: perPage)
    }
}

private final class PaginatedFetchableBatchLoader<T: PaginatedFetchable> {
    typealias ResultBlock = (Swift.Result<[T], Error>)->()

    private let operationQueue = OperationQueue()
    private let serialQueue = DispatchQueue(label: "batch.loader.serial.queue")
    private var resultItems: [T] = []
    private var batchCounter = 0
    private var resultBlock: ResultBlock?
    
    init(maxOperations: Int) {
        operationQueue.maxConcurrentOperationCount = maxOperations
    }
    
    func fetchAllPagesWithLimit(for originItems: [T.O], limit: Int, resultBlock: @escaping ResultBlock) {
        guard !originItems.isEmpty else {
            resultBlock(.success([]))
            return
        }
        self.resultBlock = resultBlock
        var items = originItems
        
        while items.count > 0 {
            batchCounter += 1
            let batch = items.prefix(limit)
            items = Array(items.dropFirst(batch.count))
            
            let operation: LoadPaginatedFetchableOperation<T> = LoadPaginatedFetchableOperation(batch: Array(batch)) { [weak self] result in
                switch result {
                case .success(let loadedItems):
                    self?.addLoadedItems(loadedItems)
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
            
            operationQueue.addOperation(operation)
        }
    }
    
    private func addLoadedItems(_ loadedItems: [T]) {
        serialQueue.sync {
            resultItems.append(contentsOf: loadedItems)
            batchCounter -= 1
            if batchCounter == 0 {
                resultBlock?(.success(resultItems))
                resultBlock = nil
            }
        }
    }
    
    private func handle(error: Error) {
        serialQueue.sync {
            if let loadingError = error as? LoadPaginatedFetchableOperation<T>.LoadError,
               loadingError == LoadPaginatedFetchableOperation.LoadError.cancelled {
                return
            } else {
                resultBlock?(.failure(error))
                resultBlock = nil
                operationQueue.cancelAllOperations()
            }
        }
    }
}

extension NetworkService {
    struct ActionsDomainInfo: Decodable {
            let id: UInt
            let name: String
            let ownerAddress: HexAddress
            let blockchain: String
        }
        
        struct ActionsTxInfo: Decodable {
            let id: UInt64
            let type: String
            let blockchain: String
            let messageToSign: String?
        }
        
        struct ActionsPaymentInfo: Decodable {
            let id: String
            let clientSecret: String
            let totalAmount: UInt
        }
        
        struct ActionsResponse: Decodable {
            let id: UInt64
            let domain: ActionsDomainInfo
            let txs: [ActionsTxInfo]
            let paymentInfo: ActionsPaymentInfo?
        }
        
        public func getActions(request: APIRequest) -> Promise<NetworkService.ActionsResponse> {
            return Promise { seal in
                fetchData(for: request.url,
                          body: request.body,
                          method: request.method,
                          extraHeaders: request.headers) { result in
                    switch result {
                    case .fulfilled(let data):
                        if let response = try? JSONDecoder().decode(ActionsResponse.self, from: data) {
                                seal.fulfill(response)
                        } else {
                            seal.reject(NetworkLayerError.badResponseOrStatusCode(code: 0, message: "Invalid actions response"))
                        }
                    case .rejected(let error): seal.reject(error)
                    }
                }
            }
        }
    
    public func getActions(request: APIRequest) async throws -> NetworkService.ActionsResponse {
        let data = try await fetchData(for: request.url,
                                       body: request.body,
                                       method: request.method,
                                       extraHeaders: request.headers)
        let response = try JSONDecoder().decode(ActionsResponse.self, from: data)
        return response
    }
                
        public func postMetaActions(_ apiRequest: APIRequest) -> Promise<Void> {
            return Promise { seal in
                fetchData(for: apiRequest.url,
                          body: apiRequest.body,
                          method: apiRequest.method,
                          extraHeaders: apiRequest.headers) { result in
                    switch result {
                    case .fulfilled(let data):
                        if let responseString = String(data: data, encoding: .utf8),
                           responseString.lowercased() == "ok" {
                            seal.fulfill(())
                        } else {
    #warning("get the list of possible errors from the endpoint")
                            seal.reject(NetworkLayerError.parsingTxsError)
                        }
                    case .rejected(let error): seal.reject(error)
                    }
                }
            }
        }
    
    public func postMetaActions(_ apiRequest: APIRequest) async throws {
        let data = try await fetchData(for: apiRequest.url,
                                       body: apiRequest.body,
                                       method: apiRequest.method,
                                       extraHeaders: apiRequest.headers)
        if let responseString = String(data: data, encoding: .utf8),
           responseString.lowercased() == "ok" {
            return
        } else {
#warning("get the list of possible errors from the endpoint")
            throw NetworkLayerError.parsingTxsError
        }
    }
}
