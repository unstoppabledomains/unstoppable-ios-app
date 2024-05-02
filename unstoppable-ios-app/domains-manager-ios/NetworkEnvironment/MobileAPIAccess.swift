//
//  MobileAPIAccess.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.12.2020.
//

import Foundation

extension NetworkService {
    static var isBackendSimulated: Bool { false }
    
    public func requestSecurityCode (for email: String, operation: DeepLinkOperation) async throws {
        guard let request = try? APIRequestBuilder().users(email: email)
            .operation(operation)
            .authenticate()
            .build() else {
            Debugger.printFailure("Couldnt build url", critical: true)
            throw NetworkLayerError.creatingURLFailed
        }
        _ = try await fetchData(for: request.url, body: request.body, extraHeaders: request.headers)
    }
    
    func updatePushNotificationsInfo(info: PushNotificationsInfo) async throws {
        guard let request = try? APIRequestBuilder()
            .apnsTokens(info: info)
            .build() else {
            Debugger.printFailure("Couldnt build url", critical: true)
            throw NetworkLayerError.creatingURLFailed
        }
         
        _ = try await fetchData(for: request.url, body: request.body, extraHeaders: request.headers)
    }
    
    func subscribePushNotificationsForWCDApp(info: WalletConnectPushNotificationsSubscribeInfo) async throws {
        guard let request = try? APIRequestBuilder()
            .wcPushNotificationsSubscribe(info: info)
            .build() else {
            Debugger.printFailure("Couldnt build url", critical: true)
            throw NetworkLayerError.creatingURLFailed
        }
        
        _ = try await fetchData(for: request.url, body: request.body, extraHeaders: request.headers)
    }
    
    func unsubscribePushNotificationsForWCDApp(info: WalletConnectPushNotificationsUnsubscribeInfo) async throws {
        guard let request = try? APIRequestBuilder()
            .wcPushNotificationsUnsubscribe(info: info)
            .build() else {
            Debugger.printFailure("Couldnt build url", critical: true)
            throw NetworkLayerError.creatingURLFailed
        }
        
        _ = try await fetchData(for: request.url, body: request.body, extraHeaders: request.headers)
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
    
    struct DomainData: Codable {
        let name: String
        let blockchain: String
        let node: String
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
    
    public func getAllUnMintedDomains(for email: String, withAccessCode code: String) async throws -> DomainsInfo {
        guard let request = try? APIRequestBuilder()
                                    .users(email: email)
                                    .secure(code: code)
                                    .fetchAllUnMintedDomains()
                                    .build() else {
            Debugger.printFailure("Couldn't build the url", critical: true)
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: request.url,
                                       method: .get,
                                       extraHeaders: request.headers)
        if let response = try? JSONDecoder().decode(DomainResponseArray.self, from: data) {
            let info = DomainsInfo(domainNames: response.domains.map({$0.name}),
                                   txCosts: response.txCosts)
            return info
        }
        if let _ = try? JSONDecoder().decode(MobileAPiErrorResponse.self, from: data) {
            throw NetworkLayerError.authorizationError
        }
        throw NetworkLayerError.parsingDomainsError
    }

    public func mint(domains: [DomainItem],
                      with email: String,
                      code: String,
                      stripeIntent: String?) async throws {
        guard let request = try? APIRequestBuilder().users(email: email)
            .secure(code: code)
            .mint(domains, stripeIntent: stripeIntent)
            .build() else {
            Debugger.printFailure("Couldn't build the mint request", critical: true)
            throw NetworkLayerError.creatingURLFailed
        }
        
        let _ = try await fetchData(for: request.url,
                                    body: request.body,
                                    extraHeaders: request.headers)
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
    
    public func getActions(request: APIRequest) async throws -> NetworkService.ActionsResponse {
        do {
            let data = try await fetchData(for: request.url,
                                           body: request.body,
                                           method: request.method,
                                           extraHeaders: request.headers)
            let response = try JSONDecoder().decode(ActionsResponse.self, from: data)
            return response
        } catch {
            throw error
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
    
    @discardableResult
    func makeActionsAPIRequest(_ request: APIRequest,
                               forDomain domain: DomainItem,
                               paymentConfirmationHandler: PaymentConfirmationHandler) async throws -> [ActionsTxInfo] {
        let actionsResponse = try await NetworkService().getActions(request: request)
        let blockchain = try BlockchainType.getType(abbreviation: actionsResponse.domain.blockchain)
        
        let payloadReturned: NetworkService.TxPayload
        if let paymentInfo = actionsResponse.paymentInfo {
            payloadReturned = try DomainItem.createTxPayload(blockchain: blockchain,
                                                             paymentInfo: paymentInfo,
                                                             txs: actionsResponse.txs)
            try await paymentConfirmationHandler.payIfNeededToUpdate(domain: domain,
                                                                     using: paymentInfo)
        } else {
            let messages = actionsResponse.txs.compactMap { $0.messageToSign }
            guard messages.count == actionsResponse.txs.count else { throw NetworkLayerError.noMessageError }
            payloadReturned = NetworkService.TxPayload(messages: messages, txCost: nil)
        }
        
        let signatures: [String] = try await UDWallet.createSignaturesByPersonalSign(messages: payloadReturned.messages, domain: domain)
        
        let requestSign = try NetworkService.getRequestForActionSign(id: actionsResponse.id,
                                                                     response: actionsResponse,
                                                                     signatures: signatures)
        try await NetworkService().postMetaActions(requestSign)
        
        return actionsResponse.txs
    }
}
