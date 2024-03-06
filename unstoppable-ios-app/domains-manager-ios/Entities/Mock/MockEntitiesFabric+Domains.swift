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
        static func mockDomainsDisplayInfo(ownerWallet: String) -> [DomainDisplayInfo] {
            var domains = [DomainDisplayInfo]()
            let tlds: [String] = ["x", "nft", "unstoppable"]
            
            for tld in tlds {
                for i in 0..<5 {
                    let domain = DomainDisplayInfo(name: "oleg_\(i)_\(ownerWallet.last!).\(tld)",
                                                   ownerWallet: ownerWallet,
                                                   blockchain: .Matic,
                                                   isSetForRR: i == 0)
                    domains.append(domain)
                }
                
                for i in 0..<5 {
                    var name = "subdomain_\(i).oleg_0.\(tld)"
                    if i == 3 {
                        name = "long_long_long_long_long_" + name
                    }
                    let domain = DomainDisplayInfo(name: name,
                                                   ownerWallet: ownerWallet,
                                                   blockchain: .Matic,
                                                   isSetForRR: false)
                    domains.append(domain)
                }
            }
                        
            return domains
        }
        
        static func mockDomainDisplayInfo(ownerWallet: String = "0x1",
                                          name: String = "preview.x",
                                          isSetForRR: Bool = false) -> DomainDisplayInfo {
            DomainDisplayInfo(name: name,
                              ownerWallet: ownerWallet,
                              isSetForRR: isSetForRR)
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
    }
}

// MARK: - Domains profiles
extension MockEntitiesFabric {
    enum DomainProfile {
        static func createPublicProfile(domain: String = "mock.x",
                                        walletAddress: String = "0x1",
                                        attributes: PublicDomainProfileAttributes = DomainProfile.createEmptyPublicProfileAttributes(),
                                        socialAccounts: SocialAccounts? = nil,
                                        social: DomainProfileSocialInfo? = nil,
                                        walletBalance: [ProfileWalletBalance]? = nil) -> SerializedPublicDomainProfile {
            .init(profile: attributes,
                  metadata: createPublicDomainMetadata(domain: domain, walletAddress: walletAddress),
                  socialAccounts: socialAccounts,
                  referralCode: nil,
                  social: social,
                  records: nil,
                  walletBalances: walletBalance)
        }
        
        static func createEmptyPublicProfileAttributes() -> PublicDomainProfileAttributes {
            PublicDomainProfileAttributes(displayName: nil,
                                          description: nil,
                                          location: nil,
                                          web2Url: nil,
                                          imagePath: nil,
                                          imageType: nil,
                                          coverPath: nil,
                                          phoneNumber: nil,
                                          domainPurchased: nil)
        }
        
        static func createPublicDomainMetadata(domain: String, walletAddress: String) -> PublicDomainProfileMetaData {
            PublicDomainProfileMetaData(domain: domain, blockchain: "MATIC", networkId: 80001, owner: walletAddress)
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
                                          domainPurchased: nil)
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
        
        static func createPublicProfileWalletBalances() -> [ProfileWalletBalance] {
            []
        }
    }
}
