//
//  PreviewUDWallet.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

extension WalletWithInfo {
    
    static let mock: [WalletWithInfo] = UDWallet.mock.map { WalletWithInfo(wallet: $0, displayInfo: .init(wallet: $0, domainsCount: Int(arc4random_uniform(3)), udDomainsCount: Int(arc4random_uniform(3))))}
    
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
    
    static let mock: [UDWallet] = [.init(aliasName: "0xc4a748796805dfa42cafe0901ec182936584cc6e", 
                                         address: "0xc4a748796805dfa42cafe0901ec182936584cc6e",
                                         type: .importedUnverified),
                                   .init(aliasName: "0xcA429897570aa7083a7D296CD0009FA286731ED2", 
                                         address: "0xcA429897570aa7083a7D296CD0009FA286731ED2",
                                         type: .generatedLocally),
                                   .init(aliasName: "UD", address: "0x3d76FC25271e53e9B4adD854f27f99d3465d02AB", 
                                         type: .generatedLocally,
                                         mockingExternalWalletType: .Rainbow)]
    
    var aliasName: String = ""
    var address: String = "0xc4a748796805dfa42cafe0901ec182936584cc6e"
    var type: WalletType = .generatedLocally
    var hasBeenBackedUp: Bool? = false
    
    func getPrivateKey() -> String? {
        switch address {
        case "0xc4a748796805dfa42cafe0901ec182936584cc6e":
            return "5e7885830346c1f2fa0d40b811b8948a311086e8fd84631ce56cc5b9ca7b28ca"
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
    
    
    var mockingExternalWalletType: ExternalWalletMake?
    var isExternalConnectionActive: Bool {
        mockingExternalWalletType != nil
    }
    
    func getExternalWallet() -> WCWalletsProvider.WalletRecord? {
        if let mockingExternalWalletType {
            return .init(id: mockingExternalWalletType.rawValue, 
                         name: "Rainbow",
                         homepage: nil,
                         appStoreLink: nil,
                         mobile: .init(native: "", universal: ""),
                         isV2Compatible: true)
            
        }
        return nil
    }
    
    func getMnemonics() -> String? {
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

struct LegacyUnitaryWallet: Codable {
    
}


extension UDWallet {
    func owns(domain: any DomainEntity) -> Bool {
        guard let domainWalletAddress = domain.ownerWallet?.normalized else { return false }
        return self.address.normalized == domainWalletAddress || self.address.normalized == domainWalletAddress
    }
}

extension String {
    static let blank: Character = " "
    var mnemonicsArray: [String] {
        self.split(separator: Self.blank).map(String.init)
    }
}
