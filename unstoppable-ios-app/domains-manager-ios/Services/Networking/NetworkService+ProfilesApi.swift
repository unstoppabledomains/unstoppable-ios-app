//
//  NetworkService+ProfilesApi.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 18.10.2022.
//

import Foundation

struct SerializedPublicDomainProfile: Decodable {
    let profile: PublicDomainProfileAttributes
    let socialAccounts: SocialAccounts?
    let referralCode: String?
}

struct SerializedUserDomainProfile: Codable {
    let profile: UserDomainProfileAttributes
    let messaging: DomainMessagingAttributes
    let socialAccounts: SocialAccounts
    let humanityCheck: UserDomainProfileHumanityCheckAttribute
    let records: [String : String]
    
    enum CodingKeys: CodingKey {
        case profile
        case messaging
        case socialAccounts
        case humanityCheck
        case records
    }
    
    init(profile: UserDomainProfileAttributes, messaging: DomainMessagingAttributes, socialAccounts: SocialAccounts, humanityCheck: UserDomainProfileHumanityCheckAttribute, records: [String : String]) {
        self.profile = profile
        self.messaging = messaging
        self.socialAccounts = socialAccounts
        self.humanityCheck = humanityCheck
        self.records = records
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.profile = (try? container.decode(UserDomainProfileAttributes.self, forKey: .profile)) ?? .init()
        self.messaging = (try? container.decode(DomainMessagingAttributes.self, forKey: .messaging)) ?? .init()
        self.socialAccounts = (try? container.decode(SocialAccounts.self, forKey: .socialAccounts)) ?? .init()
        self.humanityCheck = (try? container.decode(UserDomainProfileHumanityCheckAttribute.self, forKey: .humanityCheck)) ?? .init()
        self.records = (try? container.decode([String : String].self, forKey: .records)) ?? .init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.profile, forKey: .profile)
        try container.encode(self.messaging, forKey: .messaging)
        try container.encode(self.socialAccounts, forKey: .socialAccounts)
        try container.encode(self.humanityCheck, forKey: .humanityCheck)
        try container.encode(self.records, forKey: .records)
    }
}

struct PublicDomainProfileAttributes: Decodable {
    let displayName: String?
    let description: String?
    let location: String?
    let web2Url: String?
    let imagePath: String?
    let imageType: DomainProfileImageType?
    let coverPath: String?
    let phoneNumber: String?
    let domainPurchased: Bool?
    
    enum CodingKeys: CodingKey {
        case displayName
        case description
        case location
        case web2Url
        case imagePath
        case imageType
        case coverPath
        case phoneNumber
        case domainPurchased
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PublicDomainProfileAttributes.CodingKeys.self)
        
        self.displayName = (try? container.decode(String.self, forKey: .displayName)) ?? ""
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        self.location = (try? container.decode(String.self, forKey: .location)) ?? ""
        self.web2Url = (try? container.decode(String.self, forKey: .web2Url)) ?? ""
        self.imagePath = try? container.decodeIfPresent(String.self, forKey: .imagePath)
        self.coverPath = try? container.decodeIfPresent(String.self, forKey: .coverPath)
        self.phoneNumber = (try? container.decode(String.self, forKey: .phoneNumber)) ?? ""
        if let imageTypeString = try? container.decodeIfPresent(String.self, forKey: .imageType) {
            self.imageType = DomainProfileImageType(rawValue: imageTypeString) ?? .onChain // In future BE might start to send actual chain name for on-chain avatars
        } else {
            self.imageType = nil
        }
        self.domainPurchased = try container.decode(Bool.self, forKey: .domainPurchased)
    }
}

enum DomainProfileImageType: String, Codable {
    case onChain, offChain
    case `default` /// Means no avatar is set
}

struct UserDomainProfileAttributes: Codable {
    
    let id: UInt
    let domainId: UInt
    let privateEmail: String
    
    //CommonDomainProfileAttributes
    let displayName: String
    let description: String
    let location: String
    let web2Url: String
    let imagePath: String?
    let coverPath: String?
    let phoneNumber: String
    let imageType: DomainProfileImageType?
    let domainPurchased: Bool
    
    // DomainProfileVisibilityAttributes
    let displayNamePublic: Bool
    let descriptionPublic: Bool
    let locationPublic: Bool
    let web2UrlPublic: Bool
    let imagePathPublic: Bool
    let coverPathPublic: Bool
    let phoneNumberPublic: Bool
    
    enum CodingKeys: CodingKey {
        case id
        case domainId
        case privateEmail
        case displayName
        case description
        case location
        case web2Url
        case imagePath
        case coverPath
        case phoneNumber
        case imageType
        case domainPurchased
        case displayNamePublic
        case descriptionPublic
        case locationPublic
        case imagePathPublic
        case coverPathPublic
        case web2UrlPublic
        case phoneNumberPublic
    }
    
    internal init(id: UInt = 0,
                  domainId: UInt = 0,
                  privateEmail: String = "",
                  displayName: String = "",
                  description: String = "",
                  location: String = "",
                  web2Url: String = "",
                  imagePath: String? = nil,
                  coverPath: String? = nil,
                  phoneNumber: String = "",
                  imageType: DomainProfileImageType? = nil,
                  domainPurchased: Bool = true,
                  displayNamePublic: Bool = false,
                  descriptionPublic: Bool = false,
                  locationPublic: Bool = false,
                  imagePathPublic: Bool = false,
                  coverPathPublic: Bool = false,
                  web2UrlPublic: Bool = false,
                  phoneNumberPublic: Bool = false) {
        self.id = id
        self.domainId = domainId
        self.privateEmail = privateEmail
        self.displayName = displayName
        self.description = description
        self.location = location
        self.web2Url = web2Url
        self.imagePath = imagePath
        self.coverPath = coverPath
        self.phoneNumber = phoneNumber
        self.imageType = imageType
        self.domainPurchased = domainPurchased
        self.displayNamePublic = displayNamePublic
        self.descriptionPublic = descriptionPublic
        self.locationPublic = locationPublic
        self.imagePathPublic = imagePathPublic
        self.coverPathPublic = coverPathPublic
        self.web2UrlPublic = web2UrlPublic
        self.phoneNumberPublic = phoneNumberPublic
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<UserDomainProfileAttributes.CodingKeys> = try decoder.container(keyedBy: UserDomainProfileAttributes.CodingKeys.self)
        
        self.id = try container.decode(UInt.self, forKey: UserDomainProfileAttributes.CodingKeys.id)
        self.domainId = try container.decode(UInt.self, forKey: UserDomainProfileAttributes.CodingKeys.domainId)
        self.privateEmail = (try? container.decode(String.self, forKey: UserDomainProfileAttributes.CodingKeys.privateEmail)) ?? ""
        self.displayName = (try? container.decode(String.self, forKey: UserDomainProfileAttributes.CodingKeys.displayName)) ?? ""
        self.description = (try? container.decode(String.self, forKey: UserDomainProfileAttributes.CodingKeys.description)) ?? ""
        self.location = (try? container.decode(String.self, forKey: UserDomainProfileAttributes.CodingKeys.location)) ?? ""
        self.web2Url = (try? container.decode(String.self, forKey: UserDomainProfileAttributes.CodingKeys.web2Url)) ?? ""
        self.imagePath = try? container.decodeIfPresent(String.self, forKey: UserDomainProfileAttributes.CodingKeys.imagePath)
        self.coverPath = try? container.decodeIfPresent(String.self, forKey: UserDomainProfileAttributes.CodingKeys.coverPath)
        self.phoneNumber = (try? container.decode(String.self, forKey: UserDomainProfileAttributes.CodingKeys.phoneNumber)) ?? ""
        if let imageTypeString = try? container.decodeIfPresent(String.self, forKey: UserDomainProfileAttributes.CodingKeys.imageType) {
            self.imageType = DomainProfileImageType(rawValue: imageTypeString) ?? .onChain // In future BE might start to send actual chain name for on-chain avatars
        } else {
            self.imageType = nil
        }
        self.domainPurchased = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.domainPurchased)
        self.displayNamePublic = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.displayNamePublic)
        self.descriptionPublic = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.descriptionPublic)
        self.locationPublic = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.locationPublic)
        self.imagePathPublic = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.imagePathPublic)
        self.coverPathPublic = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.coverPathPublic)
        self.web2UrlPublic = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.web2UrlPublic)
        self.phoneNumberPublic = try container.decode(Bool.self, forKey: UserDomainProfileAttributes.CodingKeys.phoneNumberPublic)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(domainId, forKey: .domainId)
        try container.encode(privateEmail, forKey: .privateEmail)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(description, forKey: .description)
        try container.encode(location, forKey: .location)
        try container.encode(web2Url, forKey: .web2Url)
        try container.encode(imagePath, forKey: .imagePath)
        try container.encode(coverPath, forKey: .coverPath)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(imageType, forKey: .imageType)
        try container.encode(domainPurchased, forKey: .domainPurchased)
        try container.encode(displayNamePublic, forKey: .displayNamePublic)
        try container.encode(descriptionPublic, forKey: .descriptionPublic)
        try container.encode(locationPublic, forKey: .locationPublic)
        try container.encode(imagePathPublic, forKey: .imagePathPublic)
        try container.encode(coverPathPublic, forKey: .coverPathPublic)
        try container.encode(web2UrlPublic, forKey: .web2UrlPublic)
        try container.encode(phoneNumberPublic, forKey: .phoneNumberPublic)
    }
}

struct SocialAccounts: Codable {
    var twitter: SerializedDomainSocialAccount?
    var discord: SerializedDomainSocialAccount?
    var youtube: SerializedDomainSocialAccount?
    var reddit: SerializedDomainSocialAccount?
    var telegram: SerializedDomainSocialAccount?
    var linkedin: SerializedDomainSocialAccount?
    var github: SerializedDomainSocialAccount?
}

struct SerializedDomainSocialAccount: Codable, Hashable {
    var location: String
    let verified: Bool
    let `public`: Bool
}

struct DomainMessagingAttributes: Codable {
    let disabled: Bool
    let hasSkiffAlias: Bool
    let thirdPartyMessagingEnabled: Bool
    let thirdPartyMessagingConfigType: String
    let rules: [SerializedDomainMessageRule]
    
    internal init(disabled: Bool = true,
                  hasSkiffAlias: Bool = false,
                  thirdPartyMessagingEnabled: Bool = false,
                  thirdPartyMessagingConfigType: String = "none",
                  rules: [SerializedDomainMessageRule] = []) {
        self.disabled = disabled
        self.hasSkiffAlias = hasSkiffAlias
        self.thirdPartyMessagingEnabled = thirdPartyMessagingEnabled
        self.thirdPartyMessagingConfigType = thirdPartyMessagingConfigType
        self.rules = rules
    }
}

struct SerializedDomainMessageRule: Codable {
    let id: UInt
    let type: String
    let rule:  String
    let name: String
}

struct BadgesInfo: Codable, Hashable {
    let badges: [BadgeInfo]
    let refresh: BadgesRefreshInfo?
    
    struct BadgeInfo: Codable, Hashable {
        let code: String
        let name: String
        let logo:  String
        let description: String
        var linkUrl: String?
        var sponsor: String?
        
        var isUDBadge: Bool {
            guard let linkUrl,
                  let url = URL(string: linkUrl) else { return true }
            
            return url.host?.contains("unstoppabledomains") == true
        }
    }
        
    struct BadgesRefreshInfo: Codable, Hashable {
        let last: Date
        let next: Date
    }
}

struct BadgeDetailedInfo: Codable, Hashable {
    let badge: BadgesInfo.BadgeInfo
    let usage: Leaderboard
    
    struct Leaderboard: Codable, Hashable {
        let rank: Int
        let holders: Int
        let domains: Int
        let featured: [String]
    }
}

struct RefreshBadgesResponse: Codable {
    let ok: Bool
    let refresh: Bool
    let next: Date
}

struct GeneratedMessage: Decodable {
    let message: String
    let headers: SignatureComponentHeaders
}

struct SignatureComponentHeaders: Decodable {
    let domain: String
    let expires: UInt64
    let signature: String
    
    enum CodingKeys: String, CodingKey {
        case domain = "x-auth-domain"
        case expires = "x-auth-expires"
        case signature = "x-auth-signature"
    }
}

struct SearchDomainProfile: Codable {
    let name: String
    let ownerAddress: String
    let imagePath: String?
}

struct UserDomainProfileHumanityCheckAttribute: Codable {
    let verified: Bool
    
    init(verified: Bool = false) {
        self.verified = verified
    }
}

extension NetworkService {
    
    //MARK: public methods
    public func fetchPublicProfile(for domain: DomainItem, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        try await fetchPublicProfile(for: domain.name, fields: fields)
    }
    
    public func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        guard let url = Endpoint.getPublicProfile(for: domainName,
                                                  fields: fields).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, method: .get)
        guard let info = SerializedPublicDomainProfile.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    public func fetchBadgesInfo(for domain: DomainItem) async throws -> BadgesInfo {
        // https://profile.unstoppabledomains.com/api/public/aaronquirk.x/badges
        guard let url = Endpoint.getBadgesInfo(for: domain).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, method: .get)
        guard let info = BadgesInfo.objectFromData(data,
                                                   dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    public func refreshDomainBadges(for domain: DomainItem) async throws -> RefreshBadgesResponse {
        guard let url = Endpoint.refreshDomainBadges(for: domain).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, method: .get)
        guard let response = RefreshBadgesResponse.objectFromData(data,
                                                                  dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return response
    }
    
    public func fetchBadgeDetailedInfo(for badge: BadgesInfo.BadgeInfo) async throws -> BadgeDetailedInfo {
        // https://profile.unstoppabledomains.com/api/badges/opensea-tothemoonalisa
        guard let url = Endpoint.getBadgeDetailedInfo(for: badge).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, method: .get)
        guard let info = BadgeDetailedInfo.objectFromData(data,
                                                          dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    public func searchForRRDomainsWith(name: String) async throws -> [SearchDomainProfile] {
        let startTime = Date()
        guard let url = Endpoint.searchDomains(with: name, shouldHaveProfile: false, shouldBeSetAsRR: true).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, method: .get)
        Debugger.printTimeSensitiveInfo(topic: .Network, "to search for RR domains", startDate: startTime, timeout: 2)
        guard let names = [SearchDomainProfile].objectFromData(data,
                                                  dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return names
    }
    
    public func fetchUserDomainProfile(for domain: DomainItem, fields: Set<GetDomainProfileField>) async throws -> SerializedUserDomainProfile {
        let signature: String
        let expires: UInt64
        if let storedSignature = try? appContext.persistedProfileSignaturesStorage
            .getUserDomainProfileSignature(for: domain.name) {
            signature = storedSignature.sign
            expires = storedSignature.expires
        } else {
            let persistedSignature = try await createAndStorePersistedProfileSignature(for: domain)
            signature = persistedSignature.sign
            expires = persistedSignature.expires
        }
        do {
            let profile = try await fetchExtendedDomainProfile(for: domain,
                                                 expires: expires,
                                                 signature: signature,
                                                 fields: fields)
            return profile
        } catch {
            if let detectedError = error as? NetworkLayerError,
               case let .badResponseOrStatusCode(code, _) = detectedError,
               code == 403 {
                appContext.persistedProfileSignaturesStorage
                    .revokeSignatures(for: domain)
            }
            throw error
        }
    }
    
    @discardableResult
    public func createAndStorePersistedProfileSignature(for domain: DomainItem) async throws -> PersistedTimedSignature {
        let message = try await NetworkService().getGeneratedMessageToRetrieve(for: domain)
        let signature = try await domain.personalSign(message: message.message)
        let newPersistedSignature = PersistedTimedSignature(domainName: domain.name,
                                                            expires: message.headers.expires,
                                                            sign: signature,
                                                            kind: .viewUserProfile)
        try? appContext.persistedProfileSignaturesStorage
            .saveNewSignature(sign: newPersistedSignature)
        return newPersistedSignature
    }
    
    @discardableResult
    public func updateUserDomainProfile(for domain: DomainItem,
                                        request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile {
        let data = try JSONEncoder().encode(request)
        guard let body = String(data: data, encoding: .utf8) else { throw NetworkLayerError.responseFailedToParse }
        return try await updateUserDomainProfile(for: domain, body: body)
    }
    
    //MARK: private methods
    private func getGeneratedMessageToRetrieve(for domain: DomainItem) async throws -> GeneratedMessage {
        guard let url = Endpoint.getGeneratedMessageToRetrieve(for: domain).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, method: .get)
        guard let info = GeneratedMessage.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    private func fetchExtendedDomainProfile(for domain: DomainItem,
                                            expires: UInt64,
                                            signature: String,
                                            fields: Set<GetDomainProfileField>) async throws -> SerializedUserDomainProfile {
        let endpoint = try Endpoint.getDomainProfile(for: domain,
                                                     expires: expires,
                                                     signature: signature,
                                                     fields: fields)
        guard let url = endpoint.url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, method: .get, extraHeaders: endpoint.headers)
        guard let info = SerializedUserDomainProfile.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    private func getGeneratedMessageToUpdate(for domain: DomainItem,
                                             body: String) async throws -> GeneratedMessage {
        guard let url = Endpoint.getGeneratedMessageToUpdate(for: domain,
                                                             body: body).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url, body: body, method: .post)
        guard let info = GeneratedMessage.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    private func updateUserDomainProfile(for domain: DomainItem,
                                     body: String) async throws -> SerializedUserDomainProfile {
        let message = try await getGeneratedMessageToUpdate(for: domain, body: body)
        let signature = try await domain.personalSign(message: message.message)
        return try await updateDomainProfile(for: domain,
                                             with: message,
                                             signature: signature,
                                             body: body)
    }
    
    private func updateDomainProfile(for domain: DomainItem,
                                     with message: GeneratedMessage,
                                     signature: String,
                                     body: String) async throws -> SerializedUserDomainProfile {
        let endpoint = try Endpoint.updateProfile(for: domain,
                                                  with: message,
                                                  signature: signature,
                                                  body: body)
        guard let url = endpoint.url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchData(for: url,
                                       body: body,
                                       method: .post,
                                       extraHeaders: endpoint.headers)
        guard let info = SerializedUserDomainProfile.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
}


// MARK: Profile Update Request Structures
struct ProfileUpdateRequest: Encodable, Hashable {
    
    enum CodingKeys: String, CodingKey {
        case name = "displayName"
        case bio = "description"
        case location = "location"
        case website = "web2Url"
        case email = "privateEmail"
        case data = "data"
        case socialAccounts = "socialAccounts"
        case coverPath = "coverPath"
        case imagePath = "imagePath"
        case displayNamePublic = "displayNamePublic"
        case descriptionPublic = "descriptionPublic"
        case locationPublic = "locationPublic"
        case web2UrlPublic = "web2UrlPublic"
        case imagePathPublic = "imagePathPublic"
        case coverPathPublic = "coverPathPublic"
    }
    
    enum SocialAccountKeys: String, CodingKey {
        case twitter = "twitter"
        case discord = "discord"
        case youtube = "youtube"
        case reddit = "reddit"
        case telegram = "telegram"
        case linkedIn = "linkedin"
        case gitHub = "github"
        
        init(_ account: SocialAccount) {
            switch account.accountType {
            case .twitter: self = .twitter
            case .discord: self = .discord
            case .youtube: self = .youtube
            case .reddit: self = .reddit
            case .telegram: self = .telegram
            case .linkedIn: self = .linkedIn
            case .gitHub: self = .gitHub
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        if attributes.isEmpty && domainSocialAccounts.isEmpty {
            throw NetworkLayerError.emptyParameters
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !attributes.isEmpty {
            try attributes.forEach({
                switch $0 {
                case .name(let name): try container.encode(name, forKey: .name)
                case .bio(let bio): try container.encode(bio, forKey: .bio)
                case .location(let location): try container.encode(location, forKey: .location)
                case .website(let website): try container.encode(website, forKey: .website)
                case .email(let email): try container.encode(email, forKey: .email)
                case .imagePath(let imagePath): try container.encode(imagePath, forKey: .imagePath)
                case .coverPath(let coverPath): try container.encode(coverPath, forKey: .coverPath)
                case .displayNamePublic(let displayNamePublic): try container.encode(displayNamePublic, forKey: .displayNamePublic)
                case .descriptionPublic(let descriptionPublic): try container.encode(descriptionPublic, forKey: .descriptionPublic)
                case .locationPublic(let locationPublic): try container.encode(locationPublic, forKey: .locationPublic)
                case .web2UrlPublic(let web2UrlPublic): try container.encode(web2UrlPublic, forKey: .web2UrlPublic)
                case .imagePathPublic(let imagePathPublic): try container.encode(imagePathPublic, forKey: .imagePathPublic)
                case .coverPathPublic(let coverPathPublic): try container.encode(coverPathPublic, forKey: .coverPathPublic)
                case .data(let visualData): if !visualData.isEmpty {
                    var cont2 = container.nestedContainer(keyedBy: Attribute.VisualData.VisualKindCodingKeys.self,
                                                          forKey: .data)
                    for visual in visualData {
                        let key = visual.kind.codingKey
                        var cont3 = cont2.nestedContainer(keyedBy: Attribute.VisualData.VisualContentCodingKeys.self,
                                                          forKey: key)
                        try cont3.encode(visual.base64, forKey: .base64)
                        try cont3.encode(visual.type.rawValue, forKey: .type)
                    }
                }
                }
            })
        }
        if !domainSocialAccounts.isEmpty {
            var nestedContainer = container.nestedContainer(keyedBy: SocialAccountKeys.self,
                                                            forKey: .socialAccounts)
            try domainSocialAccounts.forEach({ account in
                try nestedContainer.encode(account.location, forKey: SocialAccountKeys(account))
            })
        }
    }
    
    enum Attribute: Hashable {
        case name (String)
        case bio (String)
        case location (String)
        case website (String)
        case email (String)
        case imagePath (String)
        case coverPath (String)
        case displayNamePublic (Bool)
        case descriptionPublic (Bool)
        case locationPublic (Bool)
        case web2UrlPublic (Bool)
        case imagePathPublic (Bool)
        case coverPathPublic (Bool)
        case data (Set<VisualData>)
        
        struct VisualData: Hashable {
            let kind: VisualKind
            let base64: String
            let type: FileType
            
            enum FileType: String {
                case png = "image/png"
            }
            
            enum VisualKindCodingKeys: String, CodingKey {
                case image = "image"
                case cover = "cover"
            }
            
            enum VisualKind {
                case personalAvatar
                case banner
                
                var codingKey: VisualKindCodingKeys {
                    switch self {
                    case .personalAvatar: return .image
                    case .banner: return .cover
                    }
                }
            }
            
            enum VisualContentCodingKeys: String, CodingKey {
                case base64 = "base64"
                case type = "type"
            }
        }
    }
    
    typealias AttributeSet = Set<Attribute>
    
    let attributes: AttributeSet
    let domainSocialAccounts: [SocialAccount]
}

enum GetDomainProfileField: String {
    case profile, socialAccounts, messaging, cryptoVerifications, records, humanityCheck, referralCode
}

struct SocialAccount: Hashable, Encodable {
    enum Kind: String, Encodable {
        case twitter = "twitter"
        case discord = "discord"
        case youtube = "youtube"
        case reddit = "reddit"
        case telegram = "telegram"
        case linkedIn = "linkedin"
        case gitHub = "github"
    }
    
    struct LocationContainer: Encodable {
        let location: String
    }
    
    var name: String { self.accountType.rawValue }

    let accountType: Kind
    let location: String
}
