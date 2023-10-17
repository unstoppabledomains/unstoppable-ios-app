//
//  LaunchDarklyService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation
import LaunchDarkly

final class LaunchDarklyService {
    
    typealias KeysUpdatedCallback = (String)->()
    
    private var ldClient: LDClient? { LDClient.get() }
    private var keyUpdatedCallback: KeysUpdatedCallback?

    init(mobileKey: String) {
        let config = LDConfig(mobileKey: mobileKey, autoEnvAttributes: .enabled)
        
        LDClient.start(config: config)
    }
    
}

// MARK: - Open methods
extension LaunchDarklyService {
    func subscribeToKeys(_ keys: [String],
                         keyUpdatedCallback: @escaping KeysUpdatedCallback) {
        self.keyUpdatedCallback = keyUpdatedCallback
        ldClient?.observe(keys: keys,
                          owner: self,
                          handler: { [weak self] keyToFlagDict in
            self?.observedKeysUpdated(keyToFlagDict)
        })
    }

    func valueFor(key: String,
                  defaultValue: Bool) -> Bool {
        let ldValue = ldClient?.boolVariation(forKey: key, defaultValue: defaultValue)
        return ldValue ?? defaultValue
    }
}

// MARK: - Private methods
private extension LaunchDarklyService {
    func observedKeysUpdated(_ keyToFlagDict: [LDFlagKey : LDChangedFlag]) {
        print(keyToFlagDict)
        
        for (key, _) in keyToFlagDict {
            keyUpdatedCallback?(key)
        }
    }
}
