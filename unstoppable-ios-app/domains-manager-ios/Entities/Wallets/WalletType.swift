//
//  WalletType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation

// How it was generated
enum WalletType: String, Codable {
    case privateKeyEntered
    case generatedLocally
    case defaultGeneratedLocally
    case mnemonicsEntered
    case importedUnverified
    case mpc
    case externalLinked
    
    func getICloudLabel() -> String? {
        switch self {
        case .generatedLocally, .defaultGeneratedLocally: return "GENERATED"
        case .privateKeyEntered: return "IMPORTED_BY_PRIVATE_KEY"
        case .mnemonicsEntered: return "IMPORTED_BY_MNEMONICS"
        default:    Debugger.printFailure("Invalid attempt to backup wallet with the type: \(self.rawValue)", critical: true)
            return nil
        }
    }
    
    init?(iCloudLabel: String) {
        switch iCloudLabel {
        case "GENERATED": self = .generatedLocally
        case "IMPORTED_BY_PRIVATE_KEY": self = .privateKeyEntered
        case "IMPORTED_BY_MNEMONICS": self = .mnemonicsEntered
        default:    Debugger.printFailure("Found unknown type in iCloud: \(iCloudLabel)", critical: true)
            return nil
        }
    }
}
