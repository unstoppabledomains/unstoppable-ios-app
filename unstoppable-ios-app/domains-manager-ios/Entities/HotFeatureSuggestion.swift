//
//  HotFeatureSuggestion.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct HotFeatureSuggestion: Codable, Hashable {
    
    let id: Int
    let minSupportedVersion: String
    let isEnabled: Bool
    let banner: BannerContent
    let details: DetailsItem
    let navigation: NavigationItem?
    
    struct BannerContent: Codable, Hashable {
        let title: String
        let subtitle: String
        let iconURL: URL
    }
    
    enum DetailsItem: Codable, Hashable {
        case steps(StepDetailsContent)
        
        struct StepDetailsContent: Codable, Hashable {
            let title: String
            let steps: [String]
            let imageURL: URL
        }
    }
    
    struct NavigationItem: Codable, Hashable {
        let destination: Destination
        
        enum Destination: Codable, Hashable {
            case appInbox(channelId: String?)
        }
    }
}

// MARK: - Mock
extension HotFeatureSuggestion {
    static func mock() -> HotFeatureSuggestion {
        HotFeatureSuggestion(id: 0,
                             minSupportedVersion: "4.8.0",
                             isEnabled: true,
                             banner: .init(title: "Title",
                                           subtitle: "Subtitle",
                                           iconURL: URL(fileURLWithPath: "")),
                             details: .steps(.init(title: "Get notifications from dApps", 
                                                   steps: ["Tap on the 💬 message icon in the top right corner on the home screen.",
                                                                                    "Go to the 'Apps Inbox' tab."],
                                                   imageURL: URL(fileURLWithPath: ""))),
                             navigation: nil)
    }
}
