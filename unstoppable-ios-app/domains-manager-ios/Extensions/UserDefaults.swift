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
    case primaryDomainName
    case selectedBlockchainType
    case wcFriendlyReminderShown
    case didTapPrimaryDomain
    case apnsToken
    case setupRRPromptCounter
    case preferableDomainNameForRR
    case shouldShowMintingTutorial
    case isFirstLaunchAfterProfileFeatureReleased
    case didEverUpdateDomainProfile
    case didAskToShowcaseProfileAfterFirstUpdate
    case didShowDomainProfileInfoTutorial
    case isFirstLaunchAfterGIFSupportReleased
}

extension UserDefaults {
    @UserDefaultsCodableValue(key: .onboardingData) static var onboardingData: OnboardingData?
    @UserDefaultsCodableValue(key: .onboardingNavigationInfo) static var onboardingNavigationInfo: OnboardingNavigationController.OnboardingNavigationInfo?
    @UserDefaultsCodableValue(key: .onboardingDomainsPurchasedDetails) static var onboardingDomainsPurchasedDetails: DomainsPurchasedDetails?
    @UserDefaultsValue(key: UserDefaultsKey.homeScreenSettingsButtonPressed, defaultValue: false) static var homeScreenSettingsButtonPressed: Bool
    @UserDefaultsValue(key: UserDefaultsKey.buildVersion, defaultValue: "") static var buildVersion: String
    @UserDefaultsRawRepresentableValue(key: .appearanceStyle, defaultValue: .unspecified) static var appearanceStyle: UIUserInterfaceStyle
    @UserDefaultsOptionalValue(key: .primaryDomainName) static var primaryDomainName: String?
    @UserDefaultsRawRepresentableValue(key: .selectedBlockchainType, defaultValue: .Ethereum) static var selectedBlockchainType: BlockchainType
    @UserDefaultsValue(key: UserDefaultsKey.wcFriendlyReminderShown, defaultValue: false) static var wcFriendlyReminderShown: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didTapPrimaryDomain, defaultValue: false) static var didTapPrimaryDomain: Bool
    @UserDefaultsOptionalValue(key: .apnsToken) static var apnsToken: String?
    @UserDefaultsValue(key: UserDefaultsKey.setupRRPromptCounter, defaultValue: 0) static var setupRRPromptCounter: Int
    @UserDefaultsOptionalValue(key: .preferableDomainNameForRR) static var preferableDomainNameForRR: String?
    @UserDefaultsValue(key: UserDefaultsKey.shouldShowMintingTutorial, defaultValue: true) static var shouldShowMintingTutorial: Bool
    @UserDefaultsValue(key: UserDefaultsKey.isFirstLaunchAfterProfileFeatureReleased, defaultValue: true) static var isFirstLaunchAfterProfileFeatureReleased: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didEverUpdateDomainProfile, defaultValue: false) static var didEverUpdateDomainProfile: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didAskToShowcaseProfileAfterFirstUpdate, defaultValue: false) static var didAskToShowcaseProfileAfterFirstUpdate: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didShowDomainProfileInfoTutorial, defaultValue: false) static var didShowDomainProfileInfoTutorial: Bool
    @UserDefaultsValue(key: UserDefaultsKey.isFirstLaunchAfterGIFSupportReleased, defaultValue: true) static var isFirstLaunchAfterGIFSupportReleased: Bool
}

// MARK: - Property Wrappers
@propertyWrapper
struct UserDefaultsValue<Key: RawRepresentable, Value> where Key.RawValue == String {
    
    let key: Key
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
