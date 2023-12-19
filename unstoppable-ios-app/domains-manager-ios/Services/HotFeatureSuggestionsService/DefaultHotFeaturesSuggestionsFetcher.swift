//
//  DefaultHotFeaturesSuggestionsFetcher.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct DefaultHotFeaturesSuggestionsFetcher: HotFeaturesSuggestionsFetcher {
    func loadHotFeatureSuggestions() async throws -> [HotFeatureSuggestion] {
        []
    }
    
    private struct SuggestionsResponse: Codable {
        @DecodeIgnoringFailed
        var suggestions: [HotFeatureSuggestion]
    }
}
