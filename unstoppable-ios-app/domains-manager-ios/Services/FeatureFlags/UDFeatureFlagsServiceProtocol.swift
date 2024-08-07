//
//  UDFeatureFlagsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation
import Combine

protocol UDFeatureFlagsServiceProtocol {
    var featureFlagPublisher: PassthroughSubject<UDFeatureFlag, Never> { get }

    func valueFor(flag: UDFeatureFlag) -> Bool
    func entityValueFor<T: Codable>(flag: UDFeatureFlag) -> T?
    func addListener(_ listener: UDFeatureFlagsListener)
    func removeListener(_ listener: UDFeatureFlagsListener)
}

protocol UDFeatureFlagsListener: AnyObject {
    func didUpdatedUDFeatureFlag(_ flag: UDFeatureFlag, withValue newValue: Bool)
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
