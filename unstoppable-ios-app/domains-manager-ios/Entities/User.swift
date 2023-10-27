//
//  User.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 02.10.2020.
//

import Foundation


enum UserType: String, Codable {
    case Regular, Guest
}

struct UserSettings: Codable {
    var touchIdActivated: Bool = false
    var networkType: NetworkConfig.NetworkType = .mainnet
    var isTestnetUsed: Bool {
        return self.networkType == .testnet
    }
    var onboardingDone: Bool?
    var requireSAOnAppOpening: Bool?
    
    var shouldRequireSAOnAppOpening: Bool { self.requireSAOnAppOpening ?? true }
}

struct User: Codable {
    static var instance: User = Storage.instance.getUser() ?? getDefault() {
        didSet {
            Storage.instance.save(user: self.instance)
        }
    }
    
    static func getDefault() -> User {
        return User(type: .Guest, id: defaultId)
    }
    
    let type: UserType
    let id: Int
    var email: String?
    private var settings: UserSettings = UserSettings()
    private var appVersionInfo: AppVersionInfo = AppVersionInfo()
    
    func getSettings() -> UserSettings {
        self.settings
    }
    
    mutating func update(settings: UserSettings) {
        self.settings = settings
    }
    
    func getAppVersionInfo() -> AppVersionInfo {
        self.appVersionInfo
    }
    
    mutating func update(appVersionInfo: AppVersionInfo) {
        self.appVersionInfo = appVersionInfo
    }
    
    func getWalletsNumberLimit() -> Int {
//        #if DEBUG
//        return 4
//        #else
        let appVersion = getAppVersionInfo()
        return appVersion.limits?.maxWalletAddressesRequestLimit ?? Constants.defaultWalletsNumberLimit
//        #endif
    }
}

extension User {
    static let defaultId = 0
}
