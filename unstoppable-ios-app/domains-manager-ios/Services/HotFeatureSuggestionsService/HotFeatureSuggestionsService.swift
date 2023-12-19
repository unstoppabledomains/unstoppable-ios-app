//
//  HotFeatureSuggestionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

final class HotFeatureSuggestionsService {
    
    private var cachedFeatures: [HotFeatureSuggestion] = []
    private var listenerHolders: [HotFeatureSuggestionsServiceHolder] = []
    private var didDismissSuggestion = false
    @UserDefaultsCodableValue(key: .dismissedHotFeatureSuggestions) var dismissedHotFeatureSuggestions: [HotFeatureSuggestion]?
    
    init() {
        loadSuggestions()
    }
    
}

// MARK: - HotFeatureSuggestionsServiceProtocol
extension HotFeatureSuggestionsService: HotFeatureSuggestionsServiceProtocol {
    func getSuggestionToShow() -> HotFeatureSuggestion? {
        if didDismissSuggestion {
            return nil
        }
        return cachedFeatures.first
    }
    
    func dismissHotFeatureSuggestion(_ suggestion: HotFeatureSuggestion) {
        var dismissedSuggestions = dismissedHotFeatureSuggestions ?? []
        dismissedSuggestions.append(suggestion)
        dismissedHotFeatureSuggestions = dismissedSuggestions
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
    struct SuggestionsResponse: Codable {
        @DecodeIgnoringFailed
        var suggestions: [HotFeatureSuggestion]
    }
    
    func loadSuggestions() {
        Task {
            do {
//                let response: SuggestionsResponse = try await NetworkService().loadSuggestions()
//                cachedFeatures = response.suggestions
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
        let dismissedSuggestions = dismissedHotFeatureSuggestions ?? []
        cachedFeatures = cachedFeatures.filter { suggestion in
            guard isSuggestionAvailable(suggestion) else { return false }
            
            return dismissedSuggestions.first(where: { $0.id == suggestion.id }) == nil
        }
    }
    
    func isSuggestionAvailable(_ suggestion: HotFeatureSuggestion) -> Bool {
        suggestion.isEnabled && isSuggestionAppVersionSupported(suggestion)
    }
    
    func isSuggestionAppVersionSupported(_ suggestion: HotFeatureSuggestion) -> Bool {
        guard let appVersion = try? Version.getCurrent(),
              let suggestionVersion = try? Version.parse(versionString: suggestion.minAppVersion) else { return false }
        
        return appVersion >= suggestionVersion
    }
    
    func notifyCurrentSuggestionUpdated() {
        let currentSuggestion = getSuggestionToShow()
        listenerHolders.forEach { $0.listener?.didUpdateCurrentSuggestion(currentSuggestion) }
    }
}
