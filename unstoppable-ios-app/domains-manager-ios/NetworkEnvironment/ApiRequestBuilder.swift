//
//  ApiRequestBuilder.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 28.01.2021.
//

import Foundation
enum UDApiType: String {
    case resellers = "/api/v1/resellers/mobile-app-v1"
    case resellersV2 = "/api/v2/resellers/mobile_app_v1"
    case resolution = "/api/v1/resolution"
    case webhook = "/api/webhook"

    var pathRoot: String { self.rawValue }
    
    static func getPath(for type: RequestType) -> Self {
        if type == .wcPushUnsubscribe || type == .wcPushSubscribe {
            return .webhook
        }
        if type == .actions || type == .actionsSign {
            return .resellersV2
        }
        return .resellers
    }
}

struct APIRequest {
    let url: URL
    let headers: [String: String]
    let body: String
    let method: NetworkService.HttpRequestMethod
    
    init (url: URL,
          headers: [String: String] = [:],
          body: String,
          method: NetworkService.HttpRequestMethod = .get) {
        self.url = url
        self.headers = headers.appending(dict2: NetworkConfig.stagingAccessKeyIfNecessary)
        self.body = body
        self.method = method
    }
}

enum MetaTxMethod: String {
    case resolveTo
    case reconfigure
    case setMany
    case transferFrom
    case resolveZilTo
}

enum RequestType: String {
    case authenticate = "/authenticate"
    case fetchAllUnclaimedDomains = "/domains/unclaimed"
    case claim = "/domains/claim"
    case fetchSiteWallets = "/wallets"
    case transactions = "/txs"
    case messagesToSign = "/txs/messagesToSign"
    case meta = "/txs/meta"
    case domains = "/domains"
    case version = "/version"
    
    // Push notifications
    case apnsTokens = "/push/deviceTokens"
    case wcPushSubscribe = "/wallet-connect/subscribe"
    case wcPushUnsubscribe = "/wallet-connect/unsubscribe"
   
    // Actions API
    case actionsSign = "/actions/"
    case actions = "/actions"
    
}

struct RequestToClaim: Encodable {
    let claim: DomainRequestArray
    let stripeIntent: String?
}

struct DomainRequestArray: Encodable {
    let domains: [UnmintedDomainRequest]
}

struct UnmintedDomainRequest: Encodable {
    let name: String
    let owner: String
}

// APIRequestBuilder().users(email).authenticate.build()
// APIRequestBuilder().users(email).secure(code).fetchUnclaimedDomains.build()
// APIRequestBuilder().users(email).secure(code).claim(unclaimedDomains).build()
// APIRequestBuilder().transactions(txIds).build()
// APIRequestBuilder().setMany(for: domain, keys, to: values).build()
// APIRequestBuilder().postMetaTx(for: domain, keys, to: values, signature: signature).build()
class APIRequestBuilder {
    enum APIRequestError: String, LocalizedError {
        case operationAlreadyAssigned
        case emailAlreadyAssigned
        case emailNotAssigned
        case operationNotAssigned
        case parametersNotSpecified
        case unclaimedDomainsNotSpecified
        case operationNotSpecified
        case keysOrValuesInvalid
        case noPublicKeyForZil
        case failedStringifyJson
        case invalidKeyForEncoding
        
        public var errorDescription: String? {
            return rawValue
        }
    }
        
    private var actionId: UInt64?
    
    private var secureHeader: [String: String] = [:]
    private var email: String?
    private var operation: DeepLinkOperation?
    private var code: String?
    private var ids: [Int]?
    private var domains: [DomainItem]?
    private var statusGroup: TxStatusGroup?
    private var method: NetworkService.HttpRequestMethod = .get
    
    private var body: String?
    private var type: RequestType?
    private var endpoint: Endpoint?
    
    private var paidDomainsQuantity: Int?
    
    func users(email: String) throws -> APIRequestBuilder {
        guard self.email == nil else { throw APIRequestError.emailAlreadyAssigned }
        self.email = email
        return self
    }
    
    func operation(_ operation: DeepLinkOperation) throws -> APIRequestBuilder {
        guard self.operation == nil else { throw APIRequestError.operationAlreadyAssigned }
        self.operation = operation
        return self
    }
    
    func authenticate() throws -> APIRequestBuilder {
        guard self.email != nil else { throw APIRequestError.emailNotAssigned }
        guard self.operation != nil else { throw APIRequestError.operationNotAssigned }
        self.type = .authenticate
        guard let body = buildBody(for: operation!) else { throw APIRequestError.operationNotSpecified }
        self.body = body
        return self
    }
    
    func secure(code: String) throws -> APIRequestBuilder {
        guard self.email != nil else { throw APIRequestError.emailNotAssigned }
        self.code = code
        return self
    }
    
    func fetchAllUnMintedDomains() throws -> APIRequestBuilder {
        guard email != nil,
              code != nil else { throw APIRequestError.parametersNotSpecified }
        self.type = .fetchAllUnclaimedDomains
        return self
    }
    
    func fetchSiteWallets() throws -> APIRequestBuilder {
        guard email != nil,
              code != nil else { throw APIRequestError.parametersNotSpecified }
        self.type = .fetchSiteWallets
        return self
    }
    
    func apnsTokens(info: PushNotificationsInfo) throws -> APIRequestBuilder {
        guard let body = info.jsonString() else { throw APIRequestError.parametersNotSpecified }
        self.body = body
        self.type = .apnsTokens
        return self
    }
    
    func wcPushNotificationsSubscribe(info: WalletConnectPushNotificationsSubscribeInfo) throws -> APIRequestBuilder {
        guard let body = info.jsonString() else { throw APIRequestError.parametersNotSpecified }
        self.body = body
        self.type = .wcPushSubscribe
        return self
    }
 
    func wcPushNotificationsUnsubscribe(info: WalletConnectPushNotificationsUnsubscribeInfo) throws -> APIRequestBuilder {
        guard let body = info.jsonString() else { throw APIRequestError.parametersNotSpecified }
        self.body = body
        self.type = .wcPushUnsubscribe
        return self
    }
    
    func mint(_ domains: [DomainItem], stripeIntent: String?) throws -> APIRequestBuilder {
        guard email != nil,
              code != nil,
              domains.count > 0 else { throw APIRequestError.parametersNotSpecified }
        self.type = .claim
        guard let body = buildBody(for: domains, stripeIntent: stripeIntent) else { throw APIRequestError.unclaimedDomainsNotSpecified }
        self.body = body
        return self
    }
    
    func version() -> APIRequestBuilder {
        self.type = .version
        return self
    }
  
    struct SetManyParams: Codable {
        let keys: [String]
        let values: [String]
    }
    
    struct SetManyParamsZil: Codable {
        let keys: [String]
        let values: [String]
        let publicKey: String
    }
    
    struct MethodAndParamsGenericParams<T: Codable>: Codable {
        let method: String
        let params: T
    }
    
    struct MessagesToSignRequestGeneric<T: Codable>: Codable {
        let domain: String
        let transactions : [T]
    }
    
    struct MessagesToSignRequestSetManyBody: Codable {
        let domain: String
        let transactions : [MethodAndParamsGenericParams<String>]
    }
    
    struct MethodAndParamsGenericParamsZil<T: Codable>: Codable {
        let method: String
        let params: T
    }
        
    func build() -> APIRequest {
        if let endpoint = self.endpoint {
            return APIRequest(url: endpoint.url!, headers: self.secureHeader, body: self.body ?? "")
        }
        
        guard let action = self.type else { fatalError("no action specified") }
        
        let path = UDApiType.getPath(for: action).rawValue
        var url = "\(NetworkConfig.migratedBaseUrl)\(path)"
        
        
        if let email = self.email {
            url = "\(url)/users/\(email)"
        }
        if let code = self.code {
            self.secureHeader = ["Authorization": "Bearer \(code)"]
            url = "\(url)/secure"
        }
        
        
        url = "\(url)\(action.rawValue)"
        
        if let ids = self.ids {
            url = "\(url)\(buildURL(for: ids, parameterName: "id"))"
        }
        
        if let domains = self.domains {
            url = "\(url)\(buildURL(for: domains, parameterName: "domain"))"
        }
        
        if let quantity = self.paidDomainsQuantity {
            url = "\(url)?quantity=\(quantity)"
        }
        
        if let statusGroup = self.statusGroup {
            url = "\(url)&txs[statusGroup][]=\(statusGroup.rawValue)"
        }
        
        if let actionId = self.actionId {
            url = "\(url)\(actionId)/sign"
        }
        
        let additionalHeader = NetworkConfig.stagingAccessKeyIfNecessary
        
        return APIRequest(url: URL(string: url)!,
                          headers: self.secureHeader.appending(dict2: additionalHeader),
                          body: self.body ?? "",
                          method: self.method)
    }
    
    
    private func buildBody(for operation: DeepLinkOperation) -> String? {
        struct OperationBody: Codable {
            let operation: DeepLinkOperation
        }

        let body = OperationBody(operation: operation)
        guard let jsonData = try? JSONEncoder().encode(body) else {
            Debugger.printFailure("Cannot encode requested unclaimed domains", critical: true)
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    private func buildBody(for domains: [DomainItem], stripeIntent: String?) -> String? {
        domains.forEach { if $0.ownerWallet == nil { Debugger.printFailure("no owner assigned for claiming", critical: true)}}
        let domReq = domains.map { UnmintedDomainRequest(name: $0.name, owner: $0.ownerWallet!) }
        let d = DomainRequestArray(domains: domReq)
        let toClaim = RequestToClaim(claim: d, stripeIntent: stripeIntent)
        guard let jsonData = try? JSONEncoder().encode(toClaim) else {
            Debugger.printFailure("Cannot encode requested unclaimed domains", critical: true)
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    struct MessageToSignRequest<T:Encodable>: Encodable {
        let method: String
        let domain: String
        let params: T
    }
    
    private func buildURL<T:APIRepresentable>(for array: [T], parameterName: String) -> String {
        let tail = array.reduce("") { res, element in
            let and = res == "" ? "" : "&"
            return res + and + "txs[\(parameterName)][]=\(element.apiRepresentation)"
        }
        return "?\(tail)"
    }
    
    func transactions(_ txIds: [Int]) throws -> APIRequestBuilder {
        guard txIds.count > 0 else { throw APIRequestError.parametersNotSpecified }
        self.type = .transactions
        self.ids = txIds
        return self
    }
}

extension APIRequestBuilder {
    struct MetaAction: Encodable {
        let id: UInt64
        let type: String
        let signature: String
    }
    
    struct MetaActionsContainer: Encodable {
        let elements: [MetaAction]
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            elements.forEach({try! container.encode($0)})
        }
    }
    
    func actionSign(for id: UInt64,
                     response: NetworkService.ActionsResponse,
                     signatures: [String]) throws -> APIRequestBuilder {
        self.type = .actionsSign
        self.actionId = id
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        
        var signaturesMutable = signatures
        var txs = [MetaAction]()
        for tx in response.txs {
            if tx.type == "Meta" {
                guard let sign = signaturesMutable.first else {
                    throw NetworkLayerError.noMessageError
                }
                signaturesMutable = Array(signaturesMutable.dropFirst())
                let tx = MetaAction(id: tx.id, type: tx.type, signature: sign)
                txs.append(tx)
            } else {
                Debugger.printFailure("Found not handled type of TX: \(tx.type)", critical: true)
            }
        }
        
        let container = MetaActionsContainer(elements: txs)
        let containerJsonData = try! jsonEncoder.encode(container)
        self.body = String(data: containerJsonData, encoding: .utf8)!
        self.method = .post
        return self
    }
    
    enum GasCompensationPolicy: String, Encodable {
        case alwaysCompensate = "AlwaysCompensate"
        case compensateFree = "CompensateFree"
        case neverCompensate = "NeverCompensate"
    }
    
    enum Params: Encodable {
        enum CodingKeys: CodingKey {
            case records
            case remove
        }
        
        case reverseResolution(Bool)
        case updateRecords([RecordToUpdate])
        
        func encode(to encoder: Encoder) throws {
            
            struct DynamicKey: CodingKey {
                var stringValue: String
                init?(stringValue: String) {
                    self.stringValue = stringValue
                }
                
                var intValue: Int?
                init?(intValue: Int) { fatalError() }
            }
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .reverseResolution(let remove): try container.encode(remove, forKey: .remove)
            case .updateRecords(let records): var nested = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .records)
                try records.forEach {
                    guard let key = DynamicKey(stringValue: $0.resolveKey()) else {
                        throw APIRequestError.invalidKeyForEncoding
                    }
                    try nested.encode($0.resolveValue(), forKey: key)
                }
            }
        }
    }
    
    struct ActionRequest: Encodable {
        let domain: String
        let gasCompensationPolicy: GasCompensationPolicy
        let action: DomainActionType
        let parameters: Params
    }
    
    enum DomainActionType: String, Encodable {
        case setReverseResolution = "SetReverseResolution"
        case updateRecords = "UpdateRecords"
    }
    
    func actionPostReverseResolution(for domain: DomainItem,
                    remove: Bool) throws -> APIRequestBuilder {
        self.type = .actions
        
        let jsonData = try JSONEncoder().encode(ActionRequest(domain: domain.name,
                                                              gasCompensationPolicy: .alwaysCompensate,
                                                              action: .setReverseResolution,
                                                              parameters: Params.reverseResolution(remove)))
        
        guard let body = String(data: jsonData, encoding: .utf8) else {
            Debugger.printFailure("Cannot stringify encoded JSON", critical: true)
            throw APIRequestError.failedStringifyJson
        }
        
        self.body = body
        self.method = .post
        return self
    }
    
    func actionPostUpdateRecords(for domain: DomainItem, records: [RecordToUpdate]) throws -> APIRequestBuilder {
        self.type = .actions
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let jsonData = try encoder.encode(ActionRequest(domain: domain.name,
                                                              gasCompensationPolicy: .alwaysCompensate,
                                                              action: .updateRecords,
                                                              parameters: Params.updateRecords(records)))
        
        guard let body = String(data: jsonData, encoding: .utf8) else {
            Debugger.printFailure("Cannot stringify encoded JSON", critical: true)
            throw APIRequestError.failedStringifyJson
        }
        
        self.body = body
        self.method = .post
        return self
    }
}

protocol APIRepresentable {
    var apiRepresentation: String { get }
}

extension Int: APIRepresentable {
    var apiRepresentation: String {
        "\(self)"
    }
}


// Resolution API

extension Endpoint {    
    struct OwnerArrayRequest: Encodable {
        let owner: [String]
    }
    
    static func domainsByOwnerAddressesPost(owners: [HexAddress], page: Int, perPage: Int) -> Endpoint? {
        var paramQueryItems: [URLQueryItem] = []
        paramQueryItems.append( URLQueryItem(name: "page", value: "\(page)") )
        paramQueryItems.append( URLQueryItem(name: "perPage", value: "\(perPage)") )
        
        let req = OwnerArrayRequest(owner: owners)
        guard let json = try? JSONEncoder().encode(req) else { return nil }
        return composeResolutionEndpoint(paramQueryItems: paramQueryItems,
                                         requestType: .domains,
                                         body: String(data: json))
    }
    
    struct DomainArray: Encodable {
        let domain: [String]
    }
    
    struct TxsArrayRequest: Encodable {
        let txs: DomainArray
    }
    
    static func transactionsByDomainsPost(domains: [String], page: Int, perPage: Int) -> Endpoint? {
        var paramQueryItems: [URLQueryItem] = []
        paramQueryItems.append( URLQueryItem(name: "page", value: "\(page)") )
        paramQueryItems.append( URLQueryItem(name: "perPage", value: "\(perPage)") )
        
        let req = TxsArrayRequest(txs: DomainArray(domain: domains.map({ $0 })))
        guard let json = try? JSONEncoder().encode(req) else { return nil }

        return composeResolutionEndpoint(paramQueryItems: paramQueryItems,
                                         apiType: .resellers,
                                         requestType: .transactions,
                                         body: String(data: json))
    }
    
    static private func composeResolutionEndpoint(paramQueryItems: [URLQueryItem],
                                                  apiType: UDApiType = .resolution,
                                                  requestType: RequestType,
                                                  body: String) -> Endpoint {
        return Endpoint(
            path: "\(apiType.pathRoot)\(requestType.rawValue)",
            queryItems: paramQueryItems,
            body: body
        )
    }
}

extension Dictionary where Key == String, Value == String {
    func appending(dict2: Dictionary<String, String>) -> Dictionary<String, String> {
        self.merging(dict2) { $1 }
    }
}

extension Endpoint {
    static func domainsNonNFTImages(for domains: [DomainItem]) -> Endpoint {
        var paramQueryItems: [URLQueryItem] = []
        domains.forEach {
            paramQueryItems.append(URLQueryItem(name: "domains[]", value: "\($0.name)"))
        }
        paramQueryItems.append(URLQueryItem(name: "key", value: "imagePath"))
        return Endpoint(
            path: "/api/domain-profiles",
            queryItems: paramQueryItems,
            body: ""
        )
    }
}

extension Endpoint {
    static let expirationPeriodMin: TimeInterval = 5
    static func getPublicProfile(for domain: DomainItem,
                                 fields: Set<GetDomainProfileField>) -> Endpoint {
        // https://profile.ud-staging.com/api/public/aaron.x
        let fieldsQuery = fields.map({ $0.rawValue }).joined(separator: ",")
        return Endpoint(
            host: NetworkConfig.baseProfileHost,
            path: "/api/public/\(domain.name)",
            queryItems: [URLQueryItem(name: "fields", value: fieldsQuery)],
            body: ""
        )
    }
    
    static func getBadgesInfo(for domain: DomainItem) -> Endpoint {
        //https://profile.unstoppabledomains.com/api/public/aaronquirk.x/badges
        return Endpoint(
            host: NetworkConfig.baseProfileHost,
            path: "/api/public/\(domain.name)/badges",
            queryItems: [],
            body: ""
        )
    }
    
    static func refreshDomainBadges(for domain: DomainItem) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.migratedEndpoint,
            path: "/api/domains/\(domain.name)/sync_badges",
            queryItems: [],
            body: ""
        )
    }
    
    static let yearInSecs: TimeInterval = 60 * 60 * 24 * 356
    static func getGeneratedMessageToRetrieve(for domain: DomainItem) -> Endpoint {
        // https://profile.ud-staging.com/api/user/aaron.x/signature?expiry=1765522015090
        let expiry = Int( (Date().timeIntervalSince1970 + yearInSecs) * 1000)
        return Endpoint(
            host: NetworkConfig.baseProfileHost,
            path: "/api/user/\(domain.name)/signature",
            queryItems: [URLQueryItem(name: "expiry", value: String(expiry))],
            body: ""
        )
    }
    
    static func getDomainProfile(for domain: DomainItem,
                                 with message: GeneratedMessage,
                                 signature: String,
                                 fields: Set<GetDomainProfileField>) throws -> Endpoint {
        let expires = message.headers.expires
        return try  getDomainProfile(for: domain, expires: expires, signature: signature, fields: fields)
    }
    
    static func getDomainProfile(for domain: DomainItem,
                                 expires: UInt64,
                                 signature: String,
                                 fields: Set<GetDomainProfileField>) throws -> Endpoint {
        // https://profile.ud-staging.com/api/user/aaron.x
        let expiresString = "\(expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain.name,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expiresString,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        let fieldsQuery = fields.map({ $0.rawValue }).joined(separator: ",")
        return Endpoint(
            host: NetworkConfig.baseProfileHost,
            path: "/api/user/\(domain.name)",
            queryItems: [URLQueryItem(name: "fields", value: fieldsQuery)],
            body: "",
            headers: headers
        )
    }
    
    static func getGeneratedMessageToUpdate(for domain: DomainItem, body: String) -> Endpoint {
        // https://profile.ud-staging.com/api/user/aaron.x/signature?expiry=1765522015090
        let expiry = Int( (Date().timeIntervalSince1970 + 60_000_000) * 1000)
        return Endpoint(
            host: NetworkConfig.baseProfileHost,
            path: "/api/user/\(domain.name)/signature",
            queryItems: [URLQueryItem(name: "expiry", value: String(expiry))],
            body: body
        )
    }
    
    static func updateProfile(for domain: DomainItem,
                              with message: GeneratedMessage,
                              signature: String,
                              body: String) throws -> Endpoint {
        // https://profile.ud-staging.com/api/user/aaron.x
        let expires = "\(message.headers.expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain.name,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expires,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        return Endpoint(
            host: NetworkConfig.baseProfileHost,
            path: "/api/user/\(domain.name)",
            queryItems: [],
            body: body,
            headers: headers
        )
    }
}
