//
//  LaunchDarklyService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import UIKit
import LaunchDarkly
import OSLog

final class LaunchDarklyService {
    
    typealias KeysUpdatedCallback = (String)->()
    
    private var ldClient: LDClient? { LDClient.get() }
    private var keyUpdatedCallback: KeysUpdatedCallback?

    init(mobileKey: String) {
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let contextBuilder = LDContextBuilder(key: id)
        guard case .success(let context) = contextBuilder.build() else {
            Debugger.printFailure("Failed to create context for Launch darkly", critical: true)
            return }
        
        var applicationInfo = ApplicationInfo()
        applicationInfo.applicationIdentifier(Constants.ldApplicationIdentifier)
        applicationInfo.applicationVersion(Version.getCurrentAppVersionString())
        
        var config = LDConfig(mobileKey: mobileKey, autoEnvAttributes: .enabled)
        config.applicationInfo = applicationInfo
        config.logger = .disabled 
        
        LDClient.start(config: config, context: context)
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
        if let jsonValue = ldClient?.jsonVariation(forKey: key, defaultValue: ""),
           case .object(let dictionary) = jsonValue,
           let ldValue = dictionary["isOn"],
           case .bool(let bool) = ldValue {
            return bool
        }
        let ldValue = ldClient?.boolVariation(forKey: key, defaultValue: defaultValue)
        return ldValue ?? defaultValue
    }

    func entityValueFor<T: Codable>(key: String) -> T? {
        if let jsonLDValue = ldClient?.jsonVariation(forKey: key, defaultValue: ""),
           case .object(let objectData) = jsonLDValue,
           let jsonData = objectData.jsonData() {
          
            return T.objectFromData(jsonData)
        }
        
        return nil
    }
}

// MARK: - Private methods
private extension LaunchDarklyService {
    func observedKeysUpdated(_ keyToFlagDict: [LDFlagKey : LDChangedFlag]) {
        for (key, _) in keyToFlagDict {
            keyUpdatedCallback?(key)
        }
    }
}
