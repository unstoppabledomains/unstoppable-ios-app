//
//  NetworkService+ProfilesEntities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

struct SerializedPublicDomainProfile: Decodable {
    let profile: PublicDomainProfileAttributes
    let metadata: PublicDomainProfileMetaData
    let socialAccounts: SocialAccounts?
    let social: DomainProfileSocialInfo?
    let records: [String : String]?
    let walletBalances: [ProfileWalletBalance]?
}

struct SerializedUserDomainProfile: Codable {
    let profile: UserDomainProfileAttributes
    let messaging: DomainMessagingAttributes
    let socialAccounts: SocialAccounts
    let humanityCheck: UserDomainProfileHumanityCheckAttribute
    let records: [String : String]
    let storage: UserDomainStorageDetails?
    let social: DomainProfileSocialInfo
    
    enum CodingKeys: CodingKey {
        case profile
        case messaging
        case socialAccounts
        case humanityCheck
        case records
        case storage
        case social
    }
    
    init(profile: UserDomainProfileAttributes,
         messaging: DomainMessagingAttributes,
         socialAccounts: SocialAccounts,
         humanityCheck: UserDomainProfileHumanityCheckAttribute,
         records: [String : String],
         storage: UserDomainStorageDetails?,
         social: DomainProfileSocialInfo?) {
        self.profile = profile
        self.messaging = messaging
        self.socialAccounts = socialAccounts
        self.humanityCheck = humanityCheck
        self.records = records
        self.storage = storage
        self.social = social ?? .init(followingCount: 0, followerCount: 0)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.profile = (try? container.decode(UserDomainProfileAttributes.self, forKey: .profile)) ?? .init()
        self.messaging = (try? container.decode(DomainMessagingAttributes.self, forKey: .messaging)) ?? .init()
        self.socialAccounts = (try? container.decode(SocialAccounts.self, forKey: .socialAccounts)) ?? .init()
        self.humanityCheck = (try? container.decode(UserDomainProfileHumanityCheckAttribute.self, forKey: .humanityCheck)) ?? .init()
        self.records = (try? container.decode([String : String].self, forKey: .records)) ?? .init()
        self.storage = (try? container.decode(UserDomainStorageDetails.self, forKey: .storage))
        self.social = (try? container.decode(DomainProfileSocialInfo.self, forKey: .social)) ?? .init(followingCount: 0, followerCount: 0)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.profile, forKey: .profile)
        try container.encode(self.messaging, forKey: .messaging)
        try container.encode(self.socialAccounts, forKey: .socialAccounts)
        try container.encode(self.humanityCheck, forKey: .humanityCheck)
        try container.encode(self.records, forKey: .records)
        try container.encode(self.storage, forKey: .storage)
        try container.encode(self.social, forKey: .social)
    }
    
    static func newEmpty() -> SerializedUserDomainProfile {
        SerializedUserDomainProfile(profile: .init(),
                                    messaging: .init(),
                                    socialAccounts: .init(),
                                    humanityCheck: .init(),
                                    records: [:],
                                    storage: nil,
                                    social: nil)
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
}

struct PublicDomainProfileMetaData: Decodable {
    let domain: String
    let blockchain: String
    let networkId: Int
    let owner: String
}

// MARK: - PublicDomainProfileAttributes init(from decoder:
extension PublicDomainProfileAttributes {
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
        self.domainPurchased = try? container.decode(Bool.self, forKey: .domainPurchased)
    }
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
        var groupChatId: String?
        
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
        let rank: Int?
        let holders: Int
        let domains: Int
        let featured: [String]?
    }
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

struct SearchDomainProfile: Codable, Hashable {
    let name: String
    let ownerAddress: String?
    let imagePath: String?
    let imageType: DomainProfileImageType?
}

struct UserDomainProfileHumanityCheckAttribute: Codable {
    let verified: Bool
    
    init(verified: Bool = false) {
        self.verified = verified
    }
}

struct UserDomainNotificationsPreferences: Codable {
    var blockedTopics: [String]
    var acceptedTopics: [String]
    
    enum CodingKeys: String, CodingKey {
        case blockedTopics = "blocked_topics"
        case acceptedTopics = "accepted_topics"
    }
}

struct UserDomainStorageDetails: Codable {
    let apiKey: String?
    let type: StorageType?
    
    enum StorageType: String, Codable {
        case web3 = "web3.storage"
    }
}

struct DomainProfileSocialInfo: Codable, Hashable {
    let followingCount: Int
    let followerCount: Int
}

enum DomainProfileFollowerRelationshipType: String, Codable, CaseIterable {
    case followers, following
}

struct DomainProfileFollowersResponse: Codable {
    
    let domain: String
    let data: [DomainProfileFollower]
    let relationshipType: DomainProfileFollowerRelationshipType
    let meta: CursorInfo
    
    struct CursorInfo: Codable {
        let totalCount: Int
        let pagination: Pagination
    }
    
    struct Pagination: Codable {
        let cursor: Int?
        let take: Int
    }
}

typealias SerializedDomainProfileSuggestionsResponse = [SerializedDomainProfileSuggestion]
struct SerializedDomainProfileSuggestion: Codable {
    let address: String
    let reasons: [Reason]
    let score: Int
    let domain: String
    let imageUrl: String?
    let imageType: DomainProfileImageType?
    
    struct Reason: Codable {
        let id: String
        let description: String
    }
}

struct DomainProfileFollower: Codable {
    let domain: String
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
    case profile, socialAccounts, messaging, cryptoVerifications, records, humanityCheck
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

struct UpdateProfilePendingChangesRequest {
    let pendingChanges: DomainProfilePendingChanges
    let domain: DomainItem
}

struct ProfileWalletBalance: Codable, Hashable {
    let symbol: String
    let name: String
    let balance: String
    var value: Value?
    
    struct Value: Codable, Hashable {
        let marketUsd: String?
        let walletUsd: String?
    }
}

struct WalletTokenPortfolio: Codable, Hashable {
    let address: String
    let symbol: String
    let gasCurrency: String
    let name: String
    let type: String
    let firstTx: Date?
    let lastTx: Date?
    let blockchainScanUrl: String
    let balanceAmt: Double
    let tokens: [Token]?
//    let stats: Stats?
//    let nfts: [NFT]?
    let value: Value
    let totalValueUsdAmt: Double?
    let totalValueUsd: String?
    let logoUrl: String?
    
    var totalTokensBalance: Double {
        value.walletUsdAmt + (tokens?.reduce(0.0, { $0 + ($1.value?.walletUsdAmt ?? 0) }) ?? 0)
    }
    
    struct NFT: Codable, Hashable {
        let name: String
        let description: String?
        let category: String?
        let ownedCount: Int
        let totalOwners: Int
        let totalSupply: Int
        let latestAcquiredDate: String
        let contractAddresses: [String]
        let nftIds: [String]?
        let floorPrice: [FloorPrice]?
        let totalValueUsdAmt: Double?
        let totalValueUsd: String?
    }
    
    struct FloorPrice: Codable, Hashable {
        let marketPlaceName: String
        let valueUsdAmt: Double
        let valueUsd: String
    }
    
    struct Value: Codable, Hashable {
        let marketUsd: String?
        let marketUsdAmt: Double?
        let walletUsd: String
        let walletUsdAmt: Double
        let marketPctChange24Hr: Double?
    }
    
    struct Stats: Codable, Hashable {
        let nfts: String?
        let collections: String?
        let transactions: String?
        let transfers: String?
    }
    
    struct Token: Codable, Hashable {
        let type: String
        let name: String
        let address: String
        let symbol: String
        let gasCurrency: String
        let logoUrl: String?
        let balanceAmt: Double
        let value: WalletTokenPortfolio.Value?
    }
}

// MARK: Profile Update Request Structures
struct ProfileUploadRemoteAttachmentRequest: Codable {
    let attachment: Attachment
    
    init(base64: String,
         type: String) {
        self.attachment = .init(base64: base64, type: type)
    }
    
    struct Attachment: Codable {
        let base64: String
        let type: String
    }
}

// MARK: Profile Update Request Structures
struct ProfileUploadRemoteAttachmentResponse: Codable {
    let url: URL
}

typealias SerializedRankingDomainsResponse = [SerializedRankingDomain]
struct SerializedRankingDomain: Codable {
    let rank: Int
    let domain: String
}
