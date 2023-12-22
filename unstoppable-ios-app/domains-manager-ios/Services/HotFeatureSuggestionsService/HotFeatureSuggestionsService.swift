//
//  HotFeatureSuggestionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

final class HotFeatureSuggestionsService {
    
    private let fetcher: HotFeaturesSuggestionsFetcher
    private var cachedFeatures: [HotFeatureSuggestion] = []
    private var listenerHolders: [HotFeatureSuggestionsServiceHolder] = []
    private var didDismissSuggestion = false
    private var didViewSuggestion = false
    
    init(fetcher: HotFeaturesSuggestionsFetcher) {
        self.fetcher = fetcher
        loadSuggestions()
    }
    
}

// MARK: - HotFeatureSuggestionsServiceProtocol
extension HotFeatureSuggestionsService: HotFeatureSuggestionsServiceProtocol {
    func getSuggestionToShow() -> HotFeatureSuggestion? {
        if didDismissSuggestion || didViewSuggestion {
            return nil
        }
        return cachedFeatures.first
    }
    
    func didViewHotFeatureSuggestion(_ suggestion: HotFeatureSuggestion) {
        var viewedSuggestions = HotFeatureSuggestionsStorage.getViewedHotFeatureSuggestions()
        viewedSuggestions.append(suggestion)
        HotFeatureSuggestionsStorage.setViewedHotFeatureSuggestions(viewedSuggestions)
        didViewSuggestion = true
        notifyCurrentSuggestionUpdated()
    }
    
    func dismissHotFeatureSuggestion(_ suggestion: HotFeatureSuggestion) {
        var dismissedSuggestions = HotFeatureSuggestionsStorage.getDismissedHotFeatureSuggestions()
        dismissedSuggestions.append(suggestion)
        HotFeatureSuggestionsStorage.setDismissedHotFeatureSuggestions(dismissedSuggestions)
        didDismissSuggestion = true
        notifyCurrentSuggestionUpdated()
    }
    
    func addListener(_ listener: HotFeatureSuggestionsServiceListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: HotFeatureSuggestionsServiceListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension HotFeatureSuggestionsService { 
    func loadSuggestions() {
        Task {
            do {
                cachedFeatures = try await fetcher.loadHotFeatureSuggestions()
                filterAvailableSuggestions()
                notifyCurrentSuggestionUpdated()
            } catch {
                Debugger.printFailure("Failed to load suggestions", critical: false)
                try? await Task.sleep(seconds: 30)
                loadSuggestions()
            }
        }
    }
    
    func filterAvailableSuggestions() {
        let dismissedSuggestions = HotFeatureSuggestionsStorage.getDismissedHotFeatureSuggestions()
        var viewedSuggestions = HotFeatureSuggestionsStorage.getViewedHotFeatureSuggestions()

        cachedFeatures = cachedFeatures.filter { suggestion in
            guard isSuggestionAvailable(suggestion) else { return false }
            
            let isDismissed = dismissedSuggestions.first(where: { $0.id == suggestion.id }) != nil
            let isViewed = viewedSuggestions.first(where: { $0.id == suggestion.id }) != nil

            return !isDismissed && !isViewed
        }
    }
    
    func isSuggestionAvailable(_ suggestion: HotFeatureSuggestion) -> Bool {
        suggestion.ios.isEnabled && isSuggestionAppVersionSupported(suggestion)
    }
    
    func isSuggestionAppVersionSupported(_ suggestion: HotFeatureSuggestion) -> Bool {
        guard let appVersion = try? Version.getCurrent(),
              let suggestionVersion = try? Version.parse(versionString: suggestion.ios.minSupportedVersion) else { return false }
        
        return appVersion >= suggestionVersion
    }
    
    func notifyCurrentSuggestionUpdated() {
        let currentSuggestion = getSuggestionToShow()
        listenerHolders.forEach { $0.listener?.didUpdateCurrentSuggestion(currentSuggestion) }
    }
}
