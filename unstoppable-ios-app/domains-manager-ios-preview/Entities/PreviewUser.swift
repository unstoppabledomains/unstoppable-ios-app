//
//  PreviewUser.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

struct UserSettings: Codable {
    var touchIdActivated: Bool = false
    var networkType: NetworkConfig.NetworkType = .testnet
    var isTestnetUsed: Bool {
        return self.networkType == .testnet
    }
    var onboardingDone: Bool?
    var requireSAOnAppOpening: Bool?
    
    var shouldRequireSAOnAppOpening: Bool { self.requireSAOnAppOpening ?? true }
}

struct User: Codable {
    static var instance: User = getDefault()
    static func getDefault() -> User {
        return User(id: 0)
    }
    
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
        4
    }
}
