//
//  ApiRequestBuilder.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 28.01.2021.
//

import Foundation
enum UDApiType: String {
    case resellers = "/api/v1/resellers/mobile-app-v1"
    case webhook = "/api/webhook"

    var pathRoot: String { self.rawValue }
    
    static func getPath(for type: RequestType) -> Self {
        if type == .wcPushUnsubscribe || type == .wcPushSubscribe {
            return .webhook
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
    
    init(urlString: String,
         body: Encodable? = nil,
         method: NetworkService.HttpRequestMethod,
         headers: [String : String] = [:]) throws {
        guard let url = URL(string: urlString) else { throw NetworkLayerError.creatingURLFailed }
        
        var bodyString: String = ""
        if let body {
            guard let bodyStringEncoded = body.jsonString() else { throw NetworkLayerError.responseFailedToParse }
            bodyString = bodyStringEncoded
        }
        
        self.url = url
        self.headers = headers
        self.body = bodyString
        self.method = method
    }
}

enum RequestType: String {
    case authenticate = "/authenticate"
    case fetchAllUnclaimedDomains = "/domains/unclaimed"
    case claim = "/domains/claim"
    case version = "/version"
    
    // Push notifications
    case apnsTokens = "/push/deviceTokens"
    case wcPushSubscribe = "/wallet-connect/subscribe"
    case wcPushUnsubscribe = "/wallet-connect/unsubscribe"
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
    
    func build() -> APIRequest {
        if let endpoint = self.endpoint {
            return APIRequest(url: endpoint.url!, headers: self.secureHeader, body: self.body ?? "")
        }
        
        guard let action = self.type else { fatalError("no action specified") }
        
        let path = UDApiType.getPath(for: action).rawValue
        var url = "\(NetworkConfig.baseAPIUrl)\(path)"
        
        
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
    
    private func buildURL<T:APIRepresentable>(for array: [T], parameterName: String) -> String {
        let tail = array.reduce("") { res, element in
            let and = res == "" ? "" : "&"
            return res + and + "txs[\(parameterName)][]=\(element.apiRepresentation)"
        }
        return "?\(tail)"
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
                init?(stringValue: String) {
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
        case transfer = "Transfer"
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
            host: NetworkConfig.baseAPIHost,
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
                                             chain: String?,
                                             forceRefresh: Bool) -> Endpoint {
        var queryItems: [URLQueryItem] = []
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let chain {
            queryItems.append(URLQueryItem(name: "symbols", value: chain))
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

