//
//  PreviewHotFeaturesSuggestionsFetcher.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct PreviewHotFeaturesSuggestionsFetcher: HotFeaturesSuggestionsFetcher {
    func loadHotFeatureSuggestions() async throws -> [HotFeatureSuggestion] {
        await Task.sleep(seconds: 0.7)
        return [createMockStepsSuggestion()]
    }
}

// MARK: - Private methods
private extension PreviewHotFeaturesSuggestionsFetcher {
    func createMockStepsSuggestion() -> HotFeatureSuggestion {
        .mock()
    }
}
