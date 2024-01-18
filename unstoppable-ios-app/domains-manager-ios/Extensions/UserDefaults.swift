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
    case isFirstLaunchAfterGIFSupportReleased
    case currentMessagingOwnerWallet
    case viewedHotFeatureSuggestions
    case dismissedHotFeatureSuggestions
    case didMigrateXMTPConsentsListFromUD
    case selectedWalletAddress
    
    // Purchase domains
    case purchasedDomains
    case purchasedDomainsPendingProfiles
}

extension UserDefaults {
    @UserDefaultsCodableValue(key: .onboardingData) static var onboardingData: OnboardingData?
    @UserDefaultsCodableValue(key: .onboardingNavigationInfo) static var onboardingNavigationInfo: OnboardingNavigationController.OnboardingNavigationInfo?
    @UserDefaultsCodableValue(key: .onboardingDomainsPurchasedDetails) static var onboardingDomainsPurchasedDetails: DomainsPurchasedDetails?
    @UserDefaultsValue(key: UserDefaultsKey.homeScreenSettingsButtonPressed, defaultValue: false) static var homeScreenSettingsButtonPressed: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didMigrateXMTPConsentsListFromUD, defaultValue: false) static var didMigrateXMTPConsentsListFromUD: Bool
    @UserDefaultsValue(key: UserDefaultsKey.buildVersion, defaultValue: "") static var buildVersion: String
    @UserDefaultsRawRepresentableValue(key: .appearanceStyle, defaultValue: .unspecified) static var appearanceStyle: UIUserInterfaceStyle
    @UserDefaultsRawRepresentableValue(key: .selectedBlockchainType, defaultValue: .Ethereum) static var selectedBlockchainType: BlockchainType
    @UserDefaultsValue(key: UserDefaultsKey.wcFriendlyReminderShown, defaultValue: false) static var wcFriendlyReminderShown: Bool
    @UserDefaultsOptionalValue(key: .apnsToken) static var apnsToken: String?
    @UserDefaultsValue(key: UserDefaultsKey.setupRRPromptCounter, defaultValue: 0) static var setupRRPromptCounter: Int
    @UserDefaultsOptionalValue(key: .preferableDomainNameForRR) static var preferableDomainNameForRR: String?
    @UserDefaultsValue(key: UserDefaultsKey.didEverUpdateDomainProfile, defaultValue: false) static var didEverUpdateDomainProfile: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didAskToShowcaseProfileAfterFirstUpdate, defaultValue: false) static var didAskToShowcaseProfileAfterFirstUpdate: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didShowDomainProfileInfoTutorial, defaultValue: false) static var didShowDomainProfileInfoTutorial: Bool
    @UserDefaultsValue(key: UserDefaultsKey.isFirstLaunchAfterGIFSupportReleased, defaultValue: true) static var isFirstLaunchAfterGIFSupportReleased: Bool
    @UserDefaultsValue(key: UserDefaultsKey.didShowSwipeDomainCardTutorial, defaultValue: false) static var didShowSwipeDomainCardTutorial: Bool
    @UserDefaultsOptionalValue(key: .currentMessagingOwnerWallet) static var currentMessagingOwnerWallet: String?
    @UserDefaultsOptionalValue(key: .selectedWalletAddress) static var selectedWalletAddress: String?
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
