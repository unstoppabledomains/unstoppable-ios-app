//
//  MockEntitiesFabric+Domains.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import UIKit

// MARK: - Domains
extension MockEntitiesFabric {
    enum Domains {
        static func mockDomainDisplayInfo(ownerWallet: String) -> [DomainDisplayInfo] {
            var domains = [DomainDisplayInfo]()
            let tlds: [String] = ["x", "nft", "unstoppable"]
            
            for tld in tlds {
                for i in 0..<5 {
                    let domain = DomainDisplayInfo(name: "oleg_\(i)_\(ownerWallet.last!).\(tld)",
                                                   ownerWallet: ownerWallet,
                                                   blockchain: .Matic,
                                                   isSetForRR: false)
                    domains.append(domain)
                }
                
                for i in 0..<5 {
                    let domain = DomainDisplayInfo(name: "subdomain_\(i).oleg_0.\(tld)",
                                                   ownerWallet: ownerWallet,
                                                   blockchain: .Matic,
                                                   isSetForRR: false)
                    domains.append(domain)
                }
            }
            
            return domains
        }
        
        static func mockFirebaseDomains() -> [FirebaseDomain] {
            [
                /// Parking purchased
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: Date().adding(days: 40),
                      parkingTrial: false,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "parked.x",
                      ownerAddress: "123"),
                /// Parking expires soon
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: Date().adding(days: 10),
                      parkingTrial: false,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "parking_exp_soon.x",
                      ownerAddress: "123"),
                ///Parking trial
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: Date().addingTimeInterval(60 * 60 * 24),
                      parkingTrial: true,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "on_trial.x",
                      ownerAddress: "123"),
                ///Parking expired
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: Date().addingTimeInterval(-60 * 60 * 24),
                      parkingTrial: false,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "expired.x",
                      ownerAddress: "123"),
                ///Free parking
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: nil,
                      parkingTrial: false,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "free.x",
                      ownerAddress: "123")
            ]
        }
        
        static func createPublicProfile(attributes: PublicDomainProfileAttributes = DomainProfile.createEmptyPublicProfileAttributes()) -> SerializedPublicDomainProfile {
            .init(profile: attributes,
                  socialAccounts: nil,
                  referralCode: nil,
                  social: nil,
                  records: nil,
                  walletBalances: nil)
        }
    }
}

// MARK: - Domains profiles
extension MockEntitiesFabric {
    enum DomainProfile {
        static func createEmptyPublicProfileAttributes() -> PublicDomainProfileAttributes {
            PublicDomainProfileAttributes(displayName: nil,
                                          description: nil,
                                          location: nil,
                                          web2Url: nil,
                                          imagePath: nil,
                                          imageType: nil,
                                          coverPath: nil,
                                          phoneNumber: nil,
                                          domainPurchased: nil,
                                          udBlue: false)
        }
        
        static func createPublicProfileAttributes(displayName: String = "Oleg Kuplin",
                                                  imagePath: String? = nil,
                                                  coverPath: String? = nil) -> PublicDomainProfileAttributes {
            PublicDomainProfileAttributes(displayName: displayName,
                                          description: "Unstoppable iOS developer",
                                          location: "Danang",
                                          web2Url: "ud.me/oleg.x",
                                          imagePath: imagePath,
                                          imageType: .onChain,
                                          coverPath: coverPath,
                                          phoneNumber: nil,
                                          domainPurchased: nil,
                                          udBlue: false)
        }
        
        static func createSocialAccounts() -> SocialAccounts {
            .init(twitter: createSerializedDomainSocialAccount(value: "lastsummer"),
                  discord: createSerializedDomainSocialAccount(),
                  youtube: createSerializedDomainSocialAccount(value: "https://www.youtube.com/channel/UCH7R3uNh4yqL0FmBLHXHLDg"),
                  reddit: createSerializedDomainSocialAccount(value:"TopTrending2022"),
                  telegram: createSerializedDomainSocialAccount(value: "lastsummersix"))
        }
        
        static func createSerializedDomainSocialAccount(value: String = "") -> SerializedDomainSocialAccount {
            .init(location: value, verified: true, public: true)
        }
        
        static func createDomainProfileSocialInfo(followingCount: Int = 0,
                                                  followerCount: Int = 0) -> DomainProfileSocialInfo {
            .init(followingCount: followingCount,
                  followerCount: followerCount)
        }
        
        static func createPublicProfileRecords() -> [String : String] {
            ["ETH" : "0xaldfjsflsjdflksdjflsdkjflsdkfjsldfkj"]
        }
        
        static func createFollowersListFor(domain: String,
                                           followerNames: [String],
                                           relationshipType: DomainProfileFollowerRelationshipType) -> DomainProfileFollowersResponse {
            DomainProfileFollowersResponse(domain: domain,
                                           data: followerNames.map { .init(domain: $0) },
                                           relationshipType: relationshipType,
                                           meta: .init(totalCount: followerNames.count,
                                                       pagination: .init(cursor: nil, take: followerNames.count)))
        }
    }
}

// MARK: - Explore
extension MockEntitiesFabric {
    enum Explore {
        static func createFollowersProfiles() -> [SerializedPublicDomainProfile] {
            [Domains.createPublicProfile(), // Empty
             Domains.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(imagePath: ImageURLs.aiAvatar.rawValue)), // Avatar
             Domains.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(coverPath: ImageURLs.sunset.rawValue)), // Cover path
             Domains.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(imagePath: ImageURLs.aiAvatar.rawValue, coverPath: ImageURLs.sunset.rawValue))] // Avatar and cover 1
        }
    }
}
