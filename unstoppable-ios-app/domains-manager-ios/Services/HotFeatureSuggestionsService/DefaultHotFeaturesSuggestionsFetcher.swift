//
//  DefaultHotFeaturesSuggestionsFetcher.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct DefaultHotFeaturesSuggestionsFetcher: HotFeaturesSuggestionsFetcher {
    func loadHotFeatureSuggestions() async throws -> [HotFeatureSuggestion] {
        let request = try APIRequest(urlString: "https://pr-8599.api.ud-staging.com/api/v1/resellers/mobile-app-v1/mobile-hot-suggestions",
                                 method: .get)
        
        let response: SuggestionsResponse = try await NetworkService().makeDecodableAPIRequest(request)
        
        return response.suggestions
    }
    
    private struct SuggestionsResponse: Codable {
        @DecodeIgnoringFailed
        var suggestions: [HotFeatureSuggestion]
    }
}
