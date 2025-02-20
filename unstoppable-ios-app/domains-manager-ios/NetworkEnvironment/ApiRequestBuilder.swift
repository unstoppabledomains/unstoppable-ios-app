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
    private(set) var headers: [String: String]
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
    
    init(urlString: String,
         body: Encodable? = nil,
         method: NetworkService.HttpRequestMethod,
         headers: [String : String] = [:]) throws {
        guard let url = URL(string: urlString) else { throw NetworkLayerError.creatingURLFailed }
        
        var bodyString: String = ""
        if let body {
            let bodyStringEncoded = try body.jsonStringThrowing()
            bodyString = bodyStringEncoded
        }
        
        self.url = url
        self.headers = headers
        self.body = bodyString
        self.method = method
    }
    
    mutating func updateHeaders(block: (inout [String : String])->()) {
        block(&headers)
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
        struct OperationBody: Encodable {
            let operation: DeepLinkOperation
        }

        let body = OperationBody(operation: operation)
        return body.stringify()    }
    
    private func buildBody(for domains: [DomainItem], stripeIntent: String?) -> String? {
        domains.forEach { if $0.ownerWallet == nil { Debugger.printFailure("no owner assigned for claiming", critical: true)}}
        let domReq = domains.map { UnmintedDomainRequest(name: $0.name, owner: $0.ownerWallet!) }
        let d = DomainRequestArray(domains: domReq)
        let toClaim = RequestToClaim(claim: d, stripeIntent: stripeIntent)
        return toClaim.stringify()
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

extension Encodable {
    func stringify() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            Debugger.printFailure("Cannot encode data", critical: true)
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
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
            case to
            case resetRecords
        }
        
        case reverseResolution(Bool)
        case updateRecords([RecordToUpdate])
        case transfer(receiverAddress: String, configuration: TransferDomainConfiguration)
        
        func encode(to encoder: Encoder) throws {
            
            struct DynamicKey: CodingKey {
                var stringValue: String
                init(stringValue: String) {
                    self.stringValue = stringValue
                }
                
                var intValue: Int?
                init?(intValue: Int) { fatalError() }
            }
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .reverseResolution(let remove):
                try container.encode(remove, forKey: .remove)
            case .transfer(let receiverAddress, let configuration):
                try container.encode(receiverAddress, forKey: .to)
                try container.encode(configuration.resetRecords, forKey: .resetRecords)
            case .updateRecords(let records):
                var nested = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .records)
                try records.forEach {
                    let keys = $0.resolveKeys()
                    let value = $0.resolveValue()
                    try keys.forEach { key in
                        let encodedKey = DynamicKey(stringValue: key)
                        try nested.encode(value, forKey: encodedKey)
                    }
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
        case transfer = "Transfer"
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
    
    func actionPostTransferDomain(_ domain: DomainItem,
                                  to receiverAddress: HexAddress,
                                  configuration: TransferDomainConfiguration) throws -> APIRequestBuilder {
        self.type = .actions
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let jsonData = try encoder.encode(ActionRequest(domain: domain.name,
                                                        gasCompensationPolicy: .alwaysCompensate,
                                                        action: .transfer,
                                                        parameters: Params.transfer(receiverAddress: receiverAddress,
                                                                                    configuration: configuration)))
        
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
        guard let body = String(data: json, encoding: .utf8) else {
            Debugger.printWarning("Failed to stringify data")
            return nil
        }
        return composeResolutionEndpoint(paramQueryItems: paramQueryItems,
                                         requestType: .domains,
                                         body: body)
    }
    
    struct DomainArray: Encodable {
        let domain: [String]
        let status: TxStatusGroup?
    }
    
    
    struct TxsArrayRequest: Encodable {
        let txs: DomainArray
    }
    
    static func transactionsByDomainsPost(domains: [String], 
                                          status: TxStatusGroup?,
                                          page: Int,
                                          perPage: Int) -> Endpoint? {
        var paramQueryItems: [URLQueryItem] = []
        paramQueryItems.append( URLQueryItem(name: "page", value: "\(page)") )
        paramQueryItems.append( URLQueryItem(name: "perPage", value: "\(perPage)") )
        
        let req = TxsArrayRequest(txs: DomainArray(domain: domains.map({ $0 }),
                                                   status: status))
        guard let json = try? JSONEncoder().encode(req) else { return nil }
        guard let body = String(data: json, encoding: .utf8) else {
            Debugger.printWarning("Failed to stringify data")
            return nil
        }
        return composeResolutionEndpoint(paramQueryItems: paramQueryItems,
                                         apiType: .resellers,
                                         requestType: .transactions,
                                         body: body)
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
    static let expirationPeriodMin: TimeInterval = 5
    static func getPublicProfile(for domain: DomainItem,
                                 fields: Set<GetDomainProfileField>) -> Endpoint {
        return getPublicProfile(for: domain.name, fields: fields)
    }
    
    static func getPublicProfile(for domainName: DomainName,
                                 fields: Set<GetDomainProfileField>) -> Endpoint {
        let fieldsQuery = fields.map({ $0.rawValue }).joined(separator: ",")
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/public/\(domainName)",
            queryItems: fields.isEmpty ? [] : [URLQueryItem(name: "fields", value: fieldsQuery)],
            body: ""
        )
    }
    
    static func getBadgesInfo(for domainName: DomainName) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/public/\(domainName)/badges",
            queryItems: [],
            body: ""
        )
    }
    
    static func refreshDomainBadges(for domain: DomainItem,
                                    expires: UInt64,
                                    signature: String) throws -> Endpoint {
        let address = try domain.getETHAddressThrowing()
        let expiresString = "\(expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain.name,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expiresString,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        return Endpoint(
            host: NetworkConfig.migratedEndpoint,
            path: "/profile/user/\(address)/badges",
            queryItems: [],
            body: "[]",
            headers: headers
        )
    }
    
    static func getBadgeDetailedInfo(for badge: BadgesInfo.BadgeInfo) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/badges/\(badge.code)",
            queryItems: [],
            body: ""
        )
    }
    
    static func searchDomains(with name: String,
                              shouldHaveProfile: Bool = true,
                              shouldBeSetAsRR: Bool = false) -> Endpoint {
        let queryItems: [URLQueryItem] = [.init(name: "name", value: name),
                                          .init(name: "profile-required", value: String(shouldHaveProfile)),
                                          .init(name: "reverse-resolution-required", value: String(shouldBeSetAsRR))]
        
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/search",
            queryItems: queryItems,
            body: ""
        )
    }
    
    static let yearInSecs: TimeInterval = 60 * 60 * 24 * 356
    static func getGeneratedMessageToRetrieve(for domain: DomainItem) -> Endpoint {
        let expiry = Int( (Date().timeIntervalSince1970 + yearInSecs) * 1000)
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(domain.name)/signature",
            queryItems: [URLQueryItem(name: "expiry", value: String(expiry)),
                         URLQueryItem(name: "device", value: String(true))], /// This flag will allow signature to be used in all profile API endpoints for this domain
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
        let expiresString = "\(expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain.name,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expiresString,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        let fieldsQuery = fields.map({ $0.rawValue }).joined(separator: ",")
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(domain.name)",
            queryItems: [URLQueryItem(name: "fields", value: fieldsQuery)],
            body: "",
            headers: headers
        )
    }
    
    static func getGeneratedMessageToUpdate(for domain: DomainItem, body: String) -> Endpoint {
        let expiry = Int( (Date().timeIntervalSince1970 + 60_000_000) * 1000)
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(domain.name)/signature",
            queryItems: [URLQueryItem(name: "expiry", value: String(expiry))],
            body: body
        )
    }
    
    static func updateProfile(for domain: DomainItem,
                              with message: GeneratedMessage,
                              signature: String,
                              body: String) throws -> Endpoint {
        let expires = "\(message.headers.expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain.name,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expires,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(domain.name)",
            queryItems: [],
            body: body,
            headers: headers
        )
    }
    
    static func getDomainNotificationsPreferences(for domain: DomainItem,
                                                  expires: UInt64,
                                                  signature: String,
                                                  body: String = "") throws -> Endpoint {
        let expiresString = "\(expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain.name,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expiresString,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(domain.name)/notifications/preferences",
            queryItems: [],
            body: body,
            headers: headers
        )
    }
    
    static func getFollowingStatus(for followerDomain: DomainName,
                                   followingDomain: DomainName) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/followers/\(followingDomain)/follow-status/\(followerDomain)",
            queryItems: [],
            body: ""
        )
    }
    
    static func getFollowersList(for domain: DomainName,
                                 relationshipType: DomainProfileFollowerRelationshipType,
                                 count: Int,
                                 cursor: Int?) -> Endpoint {
        var queryItems: [URLQueryItem] = [.init(name: "relationship_type", value: relationshipType.rawValue),
                                          .init(name: "take", value: "\(count)")]
        if let cursor {
            queryItems.append(.init(name: "cursor", value: "\(cursor)"))
        }
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/followers/\(domain)",
            queryItems: queryItems,
            body: ""
        )
    }
    
    
    static func follow(domainNameToFollow: String,
                       by domain: String,
                       expires: UInt64,
                       signature: String,
                       body: String) -> Endpoint {
        let expiresString = "\(expires)"
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expiresString,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/followers/\(domainNameToFollow)",
            queryItems: [],
            body: body,
            headers: headers
        )
    }
    
    static func getProfileReverseResolution(for identifier: HexAddress,
                                            supportedNameServices: [NetworkService.ProfilesSupportedNameServices]?) throws -> Endpoint {
        var queryItems: [URLQueryItem] = []
        if let supportedNameServices {
            let services = supportedNameServices.map { $0.rawValue }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "resolutionOrder", value: services))
        }
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/resolve/\(identifier)",
            queryItems: queryItems,
            body: ""
        )
    }

    static func joinBadgeCommunity(body: String) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/messaging/push/group/join",
            queryItems: [],
            body: body
        )
    }
    
    static func leaveBadgeCommunity(body: String) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/messaging/push/group/leave",
            queryItems: [],
            body: body
        )
    }
            
    static func getSpamStatus(for address: HexAddress) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/messaging/xmtp/spam/\(address)",
            queryItems: [],
            body: ""
        )
    }
    
    static func uploadRemoteAttachment(for domain: DomainItem,
                                       with timedSignature: PersistedTimedSignature,
                                       body: String) throws -> Endpoint {
        let expires = "\(timedSignature.expires)"
        let signature = timedSignature.sign
        let headers = [
            SignatureComponentHeaders.CodingKeys.domain.rawValue: domain.name,
            SignatureComponentHeaders.CodingKeys.expires.rawValue: expires,
            SignatureComponentHeaders.CodingKeys.signature.rawValue: signature
        ]
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(domain.name)/attachment",
            queryItems: [],
            body: body,
            headers: headers
        )
    }
    
    static func getProfileConnectionSuggestions(for domain: DomainName,
                                                filterFollowings: Bool) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/public/\(domain)/connections",
            queryItems: [.init(name: "recommendationsOnly", value: String(filterFollowings))],
            body: ""
        )
    }
    
    static func getProfileFollowersRanking(count: Int) -> Endpoint {
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/followers/rankings",
            queryItems: [.init(name: "count", value: String(count))],
            body: ""
        )
    }
}

// MARK: - Open methods
extension Endpoint {
    static func getCryptoPortfolio(for wallet: String, accessToken: String?) -> Endpoint {
        let queryItems: [URLQueryItem] = [.init(name: "walletFields", value: "native,token"),
                                          .init(name: "forceRefresh", value: String(Int(Date().timeIntervalSince1970)))]
        let headers: [String: String]
        if let accessToken {
            headers = NetworkBearerAuthorisationHeaderBuilderImpl.instance.buildAuthBearerHeader(token: accessToken)
        } else {
            headers = NetworkService.profilesAPIHeader
        }
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(wallet)/wallets",
            queryItems: queryItems,
            body: "",
            headers: headers
        )
    }
    
    static func getProfileWalletTransactions(for wallet: String,
                                             cursor: String?,
                                             chains: [BlockchainType]?,
                                             forceRefresh: Bool) -> Endpoint {
        var queryItems: [URLQueryItem] = []
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let chains,
           !chains.isEmpty {
            let symbolsList: String = chains.map { $0.shortCode }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "symbols", value: symbolsList))
        }
        if forceRefresh {
            queryItems.append(URLQueryItem(name: "forceRefresh", value: String(Int(Date().timeIntervalSince1970))))
        }
        return Endpoint(
            host: NetworkConfig.baseAPIHost,
            path: "/profile/user/\(wallet)/transactions",
            queryItems: queryItems,
            body: "",
            headers: NetworkService.profilesAPIHeader
        )
    }
}

