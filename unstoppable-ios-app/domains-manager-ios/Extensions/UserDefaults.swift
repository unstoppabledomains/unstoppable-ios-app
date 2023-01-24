//
//  UserDefaults.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.04.2022.
//

import UIKit

public enum UserDefaultsKey: String {
    case onboardingData
    case onboardingNavigationInfo
    case onboardingDomainsPurchasedDetails
    case homeScreenSettingsButtonPressed
    case buildVersion
    case appearanceStyle
    case selectedBlockchainType
    case wcFriendlyReminderShown
    case apnsToken
    case setupRRPromptCounter
    case preferableDomainNameForRR
    case didEverUpdateDomainProfile
    case didAskToShowcaseProfileAfterFirstUpdate
    case didShowDomainProfileInfoTutorial
    case didShowSwipeDomainCardTutorial
}

extension UserDefaults {
    @UserDefaultsCodableValue(key: .onboardingData) static var onboardingData: OnboardingData?
    @UserDefaultsCodableValue(key: .onboardingNavigationInfo) static var onboardingNavigationInfo: OnboardingNavigationController.OnboardingNavigationInfo?
    @UserDefaultsCodableValue(key: .onboardingDomainsPurchasedDetails) static var onboardingDomainsPurchasedDetails: DomainsPurchasedDetails?
    @UserDefaultsValue(key: .homeScreenSettingsButtonPressed, defaultValue: false) static var homeScreenSettingsButtonPressed: Bool
    @UserDefaultsValue(key: .buildVersion, defaultValue: "") static var buildVersion: String
    @UserDefaultsRawRepresentableValue(key: .appearanceStyle, defaultValue: .unspecified) static var appearanceStyle: UIUserInterfaceStyle
    @UserDefaultsRawRepresentableValue(key: .selectedBlockchainType, defaultValue: .Ethereum) static var selectedBlockchainType: BlockchainType
    @UserDefaultsValue(key: .wcFriendlyReminderShown, defaultValue: false) static var wcFriendlyReminderShown: Bool
    @UserDefaultsOptionalValue(key: .apnsToken) static var apnsToken: String?
    @UserDefaultsValue(key: .setupRRPromptCounter, defaultValue: 0) static var setupRRPromptCounter: Int
    @UserDefaultsOptionalValue(key: .preferableDomainNameForRR) static var preferableDomainNameForRR: String?
    @UserDefaultsValue(key: .didEverUpdateDomainProfile, defaultValue: false) static var didEverUpdateDomainProfile: Bool
    @UserDefaultsValue(key: .didAskToShowcaseProfileAfterFirstUpdate, defaultValue: false) static var didAskToShowcaseProfileAfterFirstUpdate: Bool
    @UserDefaultsValue(key: .didShowDomainProfileInfoTutorial, defaultValue: false) static var didShowDomainProfileInfoTutorial: Bool
    @UserDefaultsValue(key: .didShowSwipeDomainCardTutorial, defaultValue: false) static var didShowSwipeDomainCardTutorial: Bool
}

// MARK: - Property Wrappers
@propertyWrapper
struct UserDefaultsValue<Value> {
    
    let key: UserDefaultsKey
    let defaultValue: Value
    
    var wrappedValue: Value {
        get {
            return UserDefaults.standard.value(forKey: key.rawValue) as? Value ?? defaultValue
        }
        set { UserDefaults.standard.setValue(newValue, forKey: key.rawValue) }
    }
    
}

@propertyWrapper
struct UserDefaultsOptionalValue<Value> {
    
    let key: UserDefaultsKey
    
    var wrappedValue: Value? {
        get { UserDefaults.standard.value(forKey: key.rawValue) as? Value }
        set { UserDefaults.standard.setValue(newValue, forKey: key.rawValue) }
    }
    
}

@propertyWrapper
struct UserDefaultsRawRepresentableValue<Value: RawRepresentable> {
    
    let key: UserDefaultsKey
    let defaultValue: Value
    
    var wrappedValue: Value {
        get {
            if let rawValue = UserDefaults.standard.value(forKey: key.rawValue) as? Value.RawValue,
               let value = Value(rawValue: rawValue) {
                return value
            }
            return defaultValue
        }
        set { UserDefaults.standard.setValue(newValue.rawValue, forKey: key.rawValue) }
    }
    
}

@propertyWrapper
struct UserDefaultsRawRepresentableArrayValue<Value: RawRepresentable> {
    
    let key: UserDefaultsKey
    
    var wrappedValue: [Value]? {
        get {
            if let rawValuesArray = UserDefaults.standard.array(forKey: key.rawValue) as? [Value.RawValue] {
                return rawValuesArray.compactMap({ Value(rawValue: $0) })
            }
            return nil
        }
        set {
            if let value = newValue {
                UserDefaults.standard.setValue(value.map({ $0.rawValue}), forKey: key.rawValue)
            } else {
                UserDefaults.standard.setValue(nil, forKey: key.rawValue)
            }
        }
    }
    
}

@propertyWrapper
struct UserDefaultsCodableValue<Value: Codable> {
    
    let key: UserDefaultsKey
    
    var wrappedValue: Value? {
        get {
            if let data = UserDefaults.standard.object(forKey: key.rawValue) as? Data,
               let object: Value = Value.genericObjectFromData(data) {
                return object
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.jsonData(), forKey: key.rawValue)
        }
    }
    
}
