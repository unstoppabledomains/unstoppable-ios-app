//
//  SocialDescription.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.08.2023.
//

import UIKit

struct SocialDescription: Hashable, WebsiteURLValidator {
    let type: SocialsType
    let account: SerializedDomainSocialAccount
    
    var value: String { account.location }
    var analyticsName: String {
        switch type {
        case .twitter:
            return "twitter"
        case .discord:
            return "discord"
        case .telegram:
            return "telegram"
        case .reddit:
            return "reddit"
        case .youTube:
            return "youTube"
        case .linkedIn:
            return "linkedIn"
        case .gitHub:
            return "gitHub"
        }
    }
    
    var appURL: URL? {
        switch type {
        case .twitter:
            return URL(string: "twitter://user?screen_name=\(value)")
        case .discord:
            return URL(string: "discord://")
        case .telegram:
            return webURL
        case .reddit:
            return webURL
        case .youTube:
            return webURL
        case .linkedIn:
            return webURL
        case .gitHub:
            return webURL
        }
    }
    
    var webURL: URL? {
        switch type {
        case .twitter:
            return URL(string: "https://twitter.com/\(value)")
        case .discord:
            return URL(string: "https://discord.com")
        case .telegram:
            return URL(string: "https://t.me/\(value)")
        case .reddit:
            if isWebsiteValid(value) {
                return URL(string: value)
            }
            return URL(string: "https://www.reddit.com/user/\(value.replacingOccurrences(of: "u/", with: ""))")
        case .youTube:
            return URL(string: value)
        case .linkedIn:
            return URL(string: value)
        case .gitHub:
            return URL(string: "https://github.com/\(value)")
        }
    }
    
    @MainActor
    func openSocialAccount() {
        if let appURL,
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL,
                  UIApplication.shared.canOpenURL(webURL) {
            UIApplication.shared.open(webURL)
        }
    }
    
    func value(in accounts: SocialAccounts) -> String {
        SocialDescription.account(of: type, in: accounts)?.location ?? ""
    }
    
    static func typesFrom(accounts: SocialAccounts) -> [SocialDescription] {
        let types: [SocialsType] = [.twitter, .discord, .telegram, .reddit, .youTube, .gitHub, .linkedIn]
        return types.compactMap({
            if let account = account(of: $0, in: accounts) {
                return SocialDescription(type: $0, account: account)
            }
            return nil
        })
    }
    
    static func account(of type: SocialsType, in accounts: SocialAccounts) -> SerializedDomainSocialAccount? {
        switch type {
        case .twitter:
            return accounts.twitter
        case .discord:
            return accounts.discord
        case .telegram:
            return accounts.telegram
        case .reddit:
            return accounts.reddit
        case .youTube:
            return accounts.youtube
        case .linkedIn:
            return accounts.linkedin
        case .gitHub:
            return accounts.github
        }
    }
}
