//
//  UDFeatureFlagsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation

protocol UDFeatureFlagsServiceProtocol {
    func start()
    func valueFor(flag: UDFeatureFlag) -> Bool
    func addListener(_ listener: UDFeatureFlagsListener)
    func removeListener(_ listener: UDFeatureFlagsListener)
}

protocol UDFeatureFlagsListener: AnyObject {
    func udFeatureFlag(_ flag: UDFeatureFlag, updatedValue newValue: Bool)
}

final class UDFeatureFlagListenerHolder: Equatable {
    
    weak var listener: UDFeatureFlagsListener?
    
    init(listener: UDFeatureFlagsListener) {
        self.listener = listener
    }
    
    static func == (lhs: UDFeatureFlagListenerHolder, rhs: UDFeatureFlagListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
