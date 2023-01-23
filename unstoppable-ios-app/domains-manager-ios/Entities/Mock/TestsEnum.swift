//
//  TestsEnum.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import Foundation

#if DEBUG
enum TestsEnvironment: String {
    case isTestMode
    
    case launchState
    
    case numberOfDomains
    case wallets
    
    case isICloudAvailable
    case isBiometricEnabled
    case shouldUseBiometricAuth
    case shouldFailAuth
}

extension TestsEnvironment {
    static var isTestModeOn: Bool = {
        ProcessInfo.processInfo.arguments.contains(TestsEnvironment.isTestMode.rawValue)
    }()
    
    static var isICloudAvailableToUse: Bool = {
        (ProcessInfo.processInfo.environment[TestsEnvironment.isICloudAvailable.rawValue] ?? "1") == "1" // Enabled by default
    }()

    static var launchStateToUse: AppLaunchState = {
        AppLaunchState(rawValue: ProcessInfo.processInfo.environment[TestsEnvironment.launchState.rawValue] ?? "") ?? .home
    }()
    
    static var numberOfDomainsToUse: Int = {
        Int(ProcessInfo.processInfo.environment[TestsEnvironment.numberOfDomains.rawValue] ?? "") ?? 0
    }()
    
    static var walletsToUse: [TestWalletDescription] = {
        let str = ProcessInfo.processInfo.environment[TestsEnvironment.wallets.rawValue] ?? ""
        let wallets = TestWalletDescription.separatedWalletsStr(from: str).compactMap({ TestWalletDescription(str: $0) })
        
        return wallets
    }()
}

extension TestsEnvironment {
    enum AppLaunchState: String {
        case onboardingNew, onboardingExisting, onboardingSameUser
        case home
    }
    
    struct TestWalletDescription {
      
        let type: String
        let name: String?
        let hasBeenBackedUp: Bool
        let isExternal: Bool
        let domainNames: [String]
        
        init(type: String, name: String?, hasBeenBackedUp: Bool, isExternal: Bool, domainNames: [String] = []) {
            self.type = type
            self.name = name
            self.hasBeenBackedUp = hasBeenBackedUp
            self.isExternal = isExternal
            self.domainNames = domainNames
        }
        
        init?(str: String) {
            let components = str.components(separatedBy: ",")
            guard components.count == 5 else { return nil }
            
            // Type
            self.type = components[0]
            
            // Name
            let name = components[1]
            self.name = name.isEmpty ? nil : name
            
            // Backed up
            self.hasBeenBackedUp = components[2] == "1"
            
            // Is external
            self.isExternal = components[3] == "1"
            
            // Domain names
            self.domainNames = components[4].components(separatedBy: "&")
        }
        
        func encodedString() -> String {
            let type = self.type
            let name = self.name ?? ""
            let hasBeenBackedUp = self.hasBeenBackedUp ? "1" : "0"
            let isExternal = self.isExternal ? "1" : "0"
            let domainNames = self.domainNames.joined(separator: "&")

            return [type, name, hasBeenBackedUp, isExternal, domainNames].joined(separator: ",")
        }
        
        static func separatedWalletsStr(from str: String) -> [String] {
            str.components(separatedBy: ";")
        }
        
        static func groupedWalletsStr(from str: [String]) -> String {
            str.joined(separator: ";")
        }
        
        static func groupedWalletsStr(from wallets: [TestWalletDescription]) -> String {
            groupedWalletsStr(from: wallets.map({ $0.encodedString() }))
        }
    }
}
#endif
