//
//  UDFeatureFlagsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation

final class UDFeatureFlagsService {
    
    private let ldService: LaunchDarklyService
    private var listenerHolders: [UDFeatureFlagListenerHolder] = []

    init() {
        #if DEBUG
        let ldMobileKey = LaunchDarkly.stagingMobileKey
        #else
        let ldMobileKey = LaunchDarkly.productionMobileKey
        #endif
        ldService = LaunchDarklyService(mobileKey: ldMobileKey)
        
        DispatchQueue.main.async {
            self.subscribeToLD()
        }
    }
    
}

// MARK: - UDFeatureFlagsServiceProtocol
extension UDFeatureFlagsService: UDFeatureFlagsServiceProtocol {    
    func valueFor(flag: UDFeatureFlag) -> Bool {
        let defaultValue = getDefaultValueFor(featureFlag: flag)
        let ldValue = ldService.valueFor(key: flag.rawValue, defaultValue: defaultValue)
        return ldValue
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
private extension UDFeatureFlagsService {
    func subscribeToLD() {
        let keys = UDFeatureFlag.allCases.map { $0.rawValue }
        ldService.subscribeToKeys(keys, keyUpdatedCallback: { [weak self] key in
            self?.ldKeyUpdated(key)
        })
    }
    
    func ldKeyUpdated(_ key: String) {
        guard let flag = UDFeatureFlag(rawValue: key) else { return }
        
        let defaultValue = getDefaultValueFor(featureFlag: flag)
        let value = valueFor(flag: flag)
        if value != defaultValue {
            storeValue(value, forFeatureFlag: flag)
            notifyListenersUpdated(flag: flag, withValue: value)
        }
    }
    
    func notifyListenersUpdated(flag: UDFeatureFlag, withValue value: Bool) {
        listenerHolders.forEach { $0.listener?.udFeatureFlag(flag, updatedValue: value) }
    }
}

// MARK: - Private methods
private extension UDFeatureFlagsService {
    func getStoreKeyFor(featureFlag flag: UDFeatureFlag) -> String {
        "feature_flag_" + flag.rawValue
    }
    
    func storeValue(_ value: Bool, forFeatureFlag flag: UDFeatureFlag) {
        let key = getStoreKeyFor(featureFlag: flag)
        UserDefaults.standard.setValue(value, forKey: key)
    }
    
    func getStoredValueFor(featureFlag flag: UDFeatureFlag) -> Bool? {
        let key = getStoreKeyFor(featureFlag: flag)
        return UserDefaults.standard.value(forKey: key) as? Bool
    }
    
    func getDefaultValueFor(featureFlag flag: UDFeatureFlag) -> Bool {
        let storedValue = getStoredValueFor(featureFlag: flag)
        let defaultValue = storedValue ?? flag.defaultValue
        return defaultValue
    }
}
