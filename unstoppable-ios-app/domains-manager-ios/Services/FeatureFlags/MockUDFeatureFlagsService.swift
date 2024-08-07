//
//  MockUDFeatureFlagsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation
import Combine

final class MockUDFeatureFlagsService {
    private var listenerHolders: [UDFeatureFlagListenerHolder] = []
    private var isMocking = false
    private(set) var featureFlagPublisher = PassthroughSubject<UDFeatureFlag, Never>()

    init() {
        start()
    }
}

// MARK: - UDFeatureFlagsServiceProtocol
extension MockUDFeatureFlagsService: UDFeatureFlagsServiceProtocol {
    func valueFor(flag: UDFeatureFlag) -> Bool {
        if isMocking {
            return true
        }
        return flag.defaultValue
    }
    
    func entityValueFor<T: Codable>(flag: UDFeatureFlag) -> T? {
        nil
    }
    
    func addListener(_ listener: UDFeatureFlagsListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: UDFeatureFlagsListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension MockUDFeatureFlagsService {
    func start() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.isMocking = true
            self.notifyListenersUpdated(flag: .communityMediaEnabled, withValue: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.isMocking = false
                self.notifyListenersUpdated(flag: .communityMediaEnabled, withValue: false)
            }
        }
    }
    
    func notifyListenersUpdated(flag: UDFeatureFlag, withValue value: Bool) {
        listenerHolders.forEach { $0.listener?.didUpdatedUDFeatureFlag(flag, withValue: value) }
    }
}
