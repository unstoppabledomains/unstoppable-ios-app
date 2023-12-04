//
//  PreviewUDWallet.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

struct WalletWithInfo {
    var wallet: UDWallet
    var displayInfo: WalletDisplayInfo?
    
    var address: String { wallet.address }
    
    static let mock: [WalletWithInfo] = UDWallet.mock.map { WalletWithInfo(wallet: $0, displayInfo: .init(wallet: $0, domainsCount: Int(arc4random_uniform(3)), udDomainsCount: Int(arc4random_uniform(3))))}
    
}


struct WalletDisplayInfo: Hashable, Equatable {
    let name: String
    let address: String
    let domainsCount: Int
    let udDomainsCount: Int
    let source: Source
    let isBackedUp: Bool
    var isWithPrivateKey: Bool = false
    var reverseResolutionDomain: DomainDisplayInfo? = nil
    
    var backupState: BackupState {
        if isBackedUp {
            return .backedUp
        } else {
            switch source {
            case .locallyGenerated:
                return .locallyGeneratedNotBackedUp
            case .imported, .external:
                return .importedNotBackedUp
            }
        }
    }
    
    var isNameSet: Bool { name != address }
    var isConnected: Bool {
        switch source {
        case .locallyGenerated, .imported:
            return false
        case .external:
            return true
        }
    }
    
    var displayName: String {
        if isNameSet {
            return name
        } else {
            switch source {
            case .locallyGenerated, .imported:
                return address.walletAddressTruncated
            case .external(let name, _):
                return name
            }
        }
    }
    
    var walletSourceName: String {
        switch source {
        case .locallyGenerated:
            return "Vault"
        case .imported, .external:
            return "Wallet"
        }
    }
}

extension WalletDisplayInfo {
    init?(wallet: UDWallet,
          domainsCount: Int,
          udDomainsCount: Int,
          reverseResolutionDomain: DomainDisplayInfo? = nil) {
        if wallet.walletState == .externalLinked {
            guard let walletMake = wallet.getExternalWallet() else { return nil }
            
            self.source = .external(walletMake.name, walletMake)
            self.isBackedUp = false
            self.isWithPrivateKey = false
        } else {
            self.isBackedUp = wallet.hasBeenBackedUp == true
            switch wallet.type {
            case .generatedLocally, .defaultGeneratedLocally:
                self.source = .locallyGenerated
                self.isWithPrivateKey = false
            case .privateKeyEntered, .mnemonicsEntered, .importedUnverified:
                self.source = .imported
                self.isWithPrivateKey = wallet.type == .privateKeyEntered
            }
        }
        self.name = wallet.aliasName
        self.address = wallet.address
        self.reverseResolutionDomain = reverseResolutionDomain
        self.domainsCount = domainsCount
        self.udDomainsCount = udDomainsCount
    }
}

// MARK: - BackupState
extension WalletDisplayInfo {
    enum BackupState {
        case backedUp, locallyGeneratedNotBackedUp, importedNotBackedUp
        
        var icon: UIImage {
            switch self {
            case .backedUp, .importedNotBackedUp:
                return .checkCircle
            case .locallyGeneratedNotBackedUp:
                return .warningIconLarge
            }
        }
        
        var tintColor: UIColor {
            switch self {
            case .backedUp:
                return .foregroundSuccess
            case .locallyGeneratedNotBackedUp:
                return .foregroundWarning
            case .importedNotBackedUp:
                return .foregroundSecondary
            }
        }
    }
}

// MARK: - Source
extension WalletDisplayInfo {
    enum Source: Hashable {
        case locallyGenerated, imported, external(_ name: String, _ walletMake: ExternalWalletMake)
        
        var displayIcon: UIImage {
            switch self {
            case .locallyGenerated:
                return .udWalletListIcon
            case .external(_, let walletMake):
                return walletMake.icon
            case .imported:
                return .walletIcon
            }
        }
    }
}

extension Array where Element == WalletDisplayInfo {
    func managedWalletsSorted() -> [Element] {
        self.sorted { lhs, rhs in
            switch (lhs.source, rhs.source) {
            case (.locallyGenerated, .imported):
                return true
            default:
                return false
            }
        }
    }
}

enum ExternalWalletMake: String, Codable, Hashable {
    case Rainbow = "1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369"
    var icon: UIImage {
        switch self {
        case .Rainbow: return UIImage(named: "walletRainbow")!
        default: return .init()
        }
    }
    var name: String {
        switch self {
        case .Rainbow: return "Rainbow"
        default: return .init()
        }
    }
}

enum WalletState: String, Codable {
    case verified // private key, seed phrase
    case externalLinked // external wallet. Read only
}

enum WalletType: String, Codable {
    case privateKeyEntered
    case generatedLocally
    case defaultGeneratedLocally
    case mnemonicsEntered
    case importedUnverified
    
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

struct UDWallet: Codable, Hashable {
    
    static let mock: [UDWallet] = [.init(aliasName: "0xc4a748796805dfa42cafe0901ec182936584cc6e", address: "0xc4a748796805dfa42cafe0901ec182936584cc6e", type: .importedUnverified),
                                   .init(aliasName: "Custom name", address: "0x537e2EB956AEC859C99B3e5e28D8E45200C4Fa52", type: .importedUnverified),
                                   .init(aliasName: "0xcA429897570aa7083a7D296CD0009FA286731ED2", address: "0xcA429897570aa7083a7D296CD0009FA286731ED2", type: .generatedLocally),
                                   .init(aliasName: "UD", address: "0x3d76FC25271e53e9B4adD854f27f99d3465d02AB", type: .generatedLocally)]
    
    var aliasName: String = ""
    var address: String = "0xc4a748796805dfa42cafe0901ec182936584cc6e"
    var type: WalletType = .generatedLocally
    var hasBeenBackedUp: Bool? = false
    
    func getPrivateKey() -> String? {
        switch address {
        case "0xc4a748796805dfa42cafe0901ec182936584cc6e":
            return "5e7885830346c1f2fa0d40b811b8948a311086e8fd84631ce56cc5b9ca7b28ca"
        case "0x537e2EB956AEC859C99B3e5e28D8E45200C4Fa52":
            return "c903cc1198bbdbd54083e00dd078453fd2c42025ce61de5ba4b436a48a606061"
        case "0xcA429897570aa7083a7D296CD0009FA286731ED2":
            return "470ee355aafebd64e6ca23427d2c448cbdb8769927be85aa90904f715f844f97"
        case "0x3d76FC25271e53e9B4adD854f27f99d3465d02AB":
            return "9b2183652b21cac3615fc0020419a38508da272f7e0204bb10f892058ee7d6bb"
        default:
            return nil
        }
    }
    var walletState: WalletState {
        return self.isExternalConnectionActive ? .externalLinked : .verified
    }
    var isExternalConnectionActive: Bool {
        false
    }
    
    func getExternalWallet() -> ExternalWalletMake? {
        nil
    }
}

extension UDWallet {
    
    func signPersonal(messageString: String) -> String? {
        if messageString.hasHexPrefix {
            return signPersonalAsHexString(messageString: messageString)
        }
        
        guard let data = messageString.data(using: .utf8),
              let signature = try? self.signPersonalMessage(data) else {
            return nil
        }
        return HexAddress.hexPrefix + signature.dataToHexString()
    }
    
    private func signPersonalAsHexString(messageString: String) -> String? {
        let data = Data(messageString.droppedHexPrefix.hexToBytes())
        guard let signature = try? self.signPersonalMessage(data) else {
            return nil
        }
        return HexAddress.hexPrefix + signature.dataToHexString()
    }
    
    private func signPersonalMessage(_ personalMessageData: Data) throws -> Data? {
        guard let privateKeyString = self.getPrivateKey() else { return nil }
        return try UDWallet.signPersonalMessage(personalMessageData, with: privateKeyString)
    }
    
    static public func signPersonalMessage(_ personalMessageData: Data,
                                           with privateKeyString: String) throws -> Data? {
        nil
    }
    
    static public func signMessageHash(messageHash: Data,
                                       with privateKeyString: String) throws -> Data? {
        nil
    }
    
    static public func signMessageHash(messageHash: Data,
                                       with privateKeyData: Data) throws -> Data? {
        nil
    }
}

struct UDWalletWithPrivateSeed {
    let udWallet: UDWallet
    let privateSeed: String
    
}
struct WCWalletsProvider {
    
    struct WalletRecord: Codable, Hashable {
        let id: String
        let name: String
    }
}

struct BackedUpWallet {
    let dateTime: Date
    let passwordHash: String

}
struct LegacyUnitaryWallet: Codable {
    
}
