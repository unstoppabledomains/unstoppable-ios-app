//
//  OnboardingData.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 14.04.2022.
//

import Foundation
import UIKit

struct OnboardingData: Codable {
    
    static var mpcCredentials: MPCActivateCredentials?
    
    var wallets: [UDWallet] = []
    var passcode: String?
    var backupPassword: String?
    var loginProvider: LoginProvider?
    var didRestoreWalletsFromBackUp: Bool?
    var parkedDomains: [FirebaseDomainDisplayInfo]?
    var mpcCode: String?
    
    func persist() {
        UserDefaults.onboardingData = self
    }
    
    static func retrieve() -> OnboardingData? {
        UserDefaults.onboardingData
    }
}
