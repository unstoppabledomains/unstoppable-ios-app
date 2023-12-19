//
//  PreviewHotFeaturesSuggestionsFetcher.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

struct PreviewHotFeaturesSuggestionsFetcher: HotFeaturesSuggestionsFetcher {
    func loadHotFeatureSuggestions() async throws -> [HotFeatureSuggestion] {
        try? await Task.sleep(seconds: 0.7)
        return [createMockStepsSuggestion()]
    }
}

// MARK: - Private methods
private extension PreviewHotFeaturesSuggestionsFetcher {
    func createMockStepsSuggestion() -> HotFeatureSuggestion {
        .init(id: 0,
              isEnabled: true,
              banner: .init(title: "Title", subtitle: "Subtitle"),
              details: .steps(.init(title: "Feature details", steps: ["Step one"], image: URL(fileURLWithPath: ""))),
              minAppVersion: "0.0.1",
              navigation: nil)
    }
}
