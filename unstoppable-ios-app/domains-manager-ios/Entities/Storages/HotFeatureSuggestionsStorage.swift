//
//  HotFeatureSuggestionsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct HotFeatureSuggestionsStorage {
    @UserDefaultsCodableValue(key: .viewedHotFeatureSuggestions) private static var viewedHotFeatureSuggestions: [HotFeatureSuggestion]?
    static func getViewedHotFeatureSuggestions() -> [HotFeatureSuggestion] {
        viewedHotFeatureSuggestions ?? []
    }
    
    static func setViewedHotFeatureSuggestions(_ suggestions: [HotFeatureSuggestion]) {
        viewedHotFeatureSuggestions = suggestions
    }
    
    @UserDefaultsCodableValue(key: .dismissedHotFeatureSuggestions) private static var dismissedHotFeatureSuggestions: [HotFeatureSuggestion]?
    static func getDismissedHotFeatureSuggestions() -> [HotFeatureSuggestion] {
        dismissedHotFeatureSuggestions ?? []
    }
    
    static func setDismissedHotFeatureSuggestions(_ suggestions: [HotFeatureSuggestion]) {
        dismissedHotFeatureSuggestions = suggestions
    }
}
