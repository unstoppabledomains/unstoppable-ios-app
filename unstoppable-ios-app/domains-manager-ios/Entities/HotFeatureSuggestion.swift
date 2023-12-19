//
//  HotFeatureSuggestion.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct HotFeatureSuggestion: Codable, Hashable {
    
    let id: Int
    let isEnabled: Bool
    let banner: BannerContent
    let details: DetailsItem
    let minAppVersion: String
    let navigation: NavigationItem?
    
    struct BannerContent: Codable, Hashable {
        let title: String
        let subtitle: String
    }
    
    enum DetailsItem: Codable, Hashable {
        case steps(StepDetailsContent)
        
        struct StepDetailsContent: Codable, Hashable {
            let title: String
            let steps: [String]
            let image: URL
        }
    }
    
    struct NavigationItem: Codable, Hashable {
        let destination: Destination
        
        enum Destination: Codable, Hashable {
            case appInbox(channelId: String?)
        }
    }
    
}
