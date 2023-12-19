//
//  HotFeatureSuggestionsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct HotFeatureSuggestionsStorage {
    @UserDefaultsCodableValue(key: .dismissedHotFeatureSuggestions) private static var dismissedHotFeatureSuggestions: [HotFeatureSuggestion]?
    
    static func getDismissedHotFeatureSuggestions() -> [HotFeatureSuggestion] {
        dismissedHotFeatureSuggestions ?? []
    }
    
    static func setDismissedHotFeatureSuggestions(_ suggestions: [HotFeatureSuggestion]) {
        dismissedHotFeatureSuggestions = suggestions
    }
}
