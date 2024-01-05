//
//  DefaultHotFeaturesSuggestionsFetcher.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct DefaultHotFeaturesSuggestionsFetcher: HotFeaturesSuggestionsFetcher {
    func loadHotFeatureSuggestions() async throws -> [HotFeatureSuggestion] {
        let request = try APIRequest(urlString: NetworkConfig.hotFeatureSuggestionsURL(),
                                     method: .get)
        
        let response: SuggestionsResponse = try await NetworkService().makeDecodableAPIRequest(request)
        
        return response.suggestions
    }
    
    private struct SuggestionsResponse: Codable {
        @DecodeIgnoringFailed
        var suggestions: [HotFeatureSuggestion]
    }
}
