//
//  SocialsType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import UIKit

enum SocialsType: Hashable, WebsiteURLValidator {
    
    case twitter
    case discord
    case telegram
    case reddit
    case youTube
    case linkedIn
    case gitHub
    
    var title: String {
        switch self {
        case .twitter:
            return "Twitter"
        case .discord:
            return "Discord"
        case .telegram:
            return "Telegram"
        case .reddit:
            return "Reddit"
        case .youTube:
            return "YouTube"
        case .linkedIn:
            return "LinkedIn"
        case .gitHub:
            return "GitHub"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .twitter:
            return .twitterIcon24
        case .discord:
            return .discordIcon24
        case .telegram:
            return .telegramIcon24
        case .reddit:
            return .redditIcon24
        case .youTube:
            return .youTubeIcon24
        case .linkedIn:
            return .linkedInIcon24
        case .gitHub:
            return .gitHubIcon24
        }
    }
    
    var originalIcon: UIImage {
        switch self {
        case .twitter:
            return .twitterOriginalIcon
        case .discord:
            return .discordOriginalIcon
        case .telegram:
            return .telegramOriginalIcon
        case .reddit:
            return .redditOriginalIcon
        case .youTube:
            return .youTubeOriginalIcon
        case .linkedIn:
            return .linkedInOriginalIcon
        case .gitHub:
            return .gitHubOriginalIcon
        }
    }
    
    var placeholder: String {
        switch self {
        case .twitter:
            return "@username"
        case .discord:
            return "@username#1111"
        case .telegram:
            return "@username"
        case .reddit:
            return "u/username"
        case .youTube:
            return "/channel URL"
        case .linkedIn:
            return ""
        case .gitHub:
            return "username"
        }
    }
    
    var styleColor: UIColor {
        switch self {
        case .twitter:
            return #colorLiteral(red: 0.3495665193, green: 0.6941498518, blue: 0.9350705147, alpha: 1)
        case .discord:
            return #colorLiteral(red: 0.3495665193, green: 0.6941498518, blue: 0.9350705147, alpha: 1)
        case .telegram:
            return #colorLiteral(red: 0.3495665193, green: 0.6941498518, blue: 0.9350705147, alpha: 1)
        case .reddit:
            return #colorLiteral(red: 0.3495665193, green: 0.6941498518, blue: 0.9350705147, alpha: 1)
        case .youTube:
            return #colorLiteral(red: 0.3495665193, green: 0.6941498518, blue: 0.9350705147, alpha: 1)
        case .linkedIn:
            return #colorLiteral(red: 0.3495665193, green: 0.6941498518, blue: 0.9350705147, alpha: 1)
        case .gitHub:
            return #colorLiteral(red: 0.3495665193, green: 0.6941498518, blue: 0.9350705147, alpha: 1)
        }
    }
    
    var prefix: String {
        switch self {
        case .twitter, .telegram:
            return "@"
        case .reddit:
            return "u/"
        case .youTube, .linkedIn, .gitHub:
            return "/"
        case .discord:
            return ""
        }
    }
    
    func formattedValue(_ value: String) -> String {
        switch self {
        case .twitter, .discord, .telegram:
            return value.replacingOccurrences(of: "@", with: "")
        case .reddit:
            if isWebsiteValid(value),
               let url = URL(string: value) {
                return url.lastPathComponent
            }
            return value.replacingOccurrences(of: "u/", with: "")
        case .youTube, .linkedIn, .gitHub:
            if isWebsiteValid(value),
               let url = URL(string: value) {
                return url.pathComponents.suffix(2).joined(separator: "/")
            }
            return value
        }
    }
    
    func displayStringForValue(_ value: String) -> String {
        let formattedValue = formattedValue(value)
        let displayValue = prefix + formattedValue
        return displayValue
    }
}

