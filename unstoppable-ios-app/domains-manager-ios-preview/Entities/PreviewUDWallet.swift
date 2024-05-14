//
//  PreviewUDWallet.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

struct UDWallet: Codable, Hashable {
    
    var aliasName: String = ""
    var address: String = "0xc4a748796805dfa42cafe0901ec182936584cc6e"
    var type: WalletType = .generatedLocally
    var hasBeenBackedUp: Bool? = false
    private(set) var mpcMetadata: MPCWalletMetadata?
    
    struct WalletConnectionInfo: Codable {
        var externalWallet: WCWalletsProvider.WalletRecord
    }
    
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
    
    private var walletConnectionInfo: WalletConnectionInfo?
   
    func getExternalWallet() -> WCWalletsProvider.WalletRecord? {
        walletConnectionInfo?.externalWallet
    }
    
    
    func getExternalWalletName() -> String? {
        walletConnectionInfo?.externalWallet.name
    }
    
    
    func getMnemonics() -> String? {
        nil
    }
    
    static func createMPC(address: String,
                          mpcMetadata: MPCWalletMetadata) -> UDWallet {
        .init(address: address,
              type: .mpc,
              mpcMetadata: mpcMetadata)
    }
    
    static func == (lhs: UDWallet, rhs: UDWallet) -> Bool {
        let resultEth = (lhs.address == rhs.address) && lhs.address != nil
        return resultEth
    }
    
    static func createUnverified(aliasName: String? = nil,
                                 address: HexAddress) -> UDWallet? {
        let name = aliasName == nil ? address : aliasName!
        return UDWallet(aliasName: name,
                        address: address,
                        type: .importedUnverified,
                        hasBeenBackedUp: false)
    }
    static func createLinked(aliasName: String,
                             address: String,
                             externalWallet: WCWalletsProvider.WalletRecord) -> UDWallet {
        var udWallet = UDWallet(aliasName: aliasName,
                                address: address,
                                type: .externalLinked,
                                hasBeenBackedUp: false)
        udWallet.walletConnectionInfo = UDWallet.WalletConnectionInfo(externalWallet: externalWallet)
        
        return udWallet
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.address)
        hasher.combine(self.aliasName)
        hasher.combine(self.hasBeenBackedUp)
        hasher.combine(self.type)
    }
    func extractMPCMetadata() throws -> MPCWalletMetadata {
        guard let mpcMetadata else { throw UDWallet.Error.failedToFindMPCMetadata }
        
        return mpcMetadata
    }
    
    enum Error: String, Swift.Error, RawValueLocalizable {
        case failedSignature
        case failedToFindMPCMetadata
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
