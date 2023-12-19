//
//  HotFeatureSuggestionsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

protocol HotFeatureSuggestionsServiceProtocol {
    func getSuggestionToShow() -> HotFeatureSuggestion?
    func dismissHotFeatureSuggestion(_ suggestion: HotFeatureSuggestion)
    
    // Listeners
    func addListener(_ listener: HotFeatureSuggestionsServiceListener)
    func removeListener(_ listener: HotFeatureSuggestionsServiceListener)
}

protocol HotFeatureSuggestionsServiceListener: AnyObject {
    func didUpdateCurrentSuggestion(_ suggestion: HotFeatureSuggestion?)
}

final class HotFeatureSuggestionsServiceHolder: Equatable {
    
    weak var listener: HotFeatureSuggestionsServiceListener?
    
    init(listener: HotFeatureSuggestionsServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: HotFeatureSuggestionsServiceHolder, rhs: HotFeatureSuggestionsServiceHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
