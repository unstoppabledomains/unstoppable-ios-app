//
//  UDWallet.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 17.03.2021.
//

import Foundation
import web3swift
import CryptoSwift
import Boilertalk_Web3
import UIKit

struct UDWallet: Codable, @unchecked Sendable {
    enum Error: String, Swift.Error, RawValueLocalizable {
        case failedToSignMessage = "Failed to Sign Message"
        case noWalletOwner = "No Owner Wallet Specified"
        case failedToFindWallet = "Failed to Find a Wallet"
        case failedSignature
        case failedToFindMPCMetadata
        case failedToRetrievePK
        case failedToRetrieveSP
    }
    
    struct WalletConnectionInfo: Codable {
        var externalWallet: WCWalletsProvider.WalletRecord
    }
    
    var aliasName: String
    var type: WalletType
    var ethWallet: UDWalletEthereum?
    var hasBeenBackedUp: Bool? = false
    
    private var walletConnectionInfo: WalletConnectionInfo?
    private(set) var mpcMetadata: MPCWalletMetadata?
    
    private init(aliasName: String,
                 walletType: WalletType,
                 ethWallet: UDWalletEthereum?,
                 hasBeenBackedUp: Bool = false) {
        self.aliasName = aliasName
        self.type = walletType
        self.ethWallet = ethWallet
        self.hasBeenBackedUp = hasBeenBackedUp
    }
    
    static func create(backedupWallet: BackedUpWallet, password: String) async throws -> UDWalletWithPrivateSeed {
        let encryptedArray = backedupWallet.encryptedPrivateSeed.description.hexToBytes()
        guard  let privateKeyOrSeed = try? Encrypting.decrypt(encryptedMessage: encryptedArray,
                                                              password: password) else {
            Debugger.printFailure("Failed to decrypt private key or seed in \(backedupWallet)", critical: true)
            throw ValetError.failedToDecrypt
        }
        
        if backedupWallet.type == .privateKeyEntered  {
            return try await UDWalletWithPrivateSeed.create(aliasName: backedupWallet.name,
                                                            type: backedupWallet.type,
                                                            privateKeyEthereum: privateKeyOrSeed)
        }
        else {
            return try await UDWalletWithPrivateSeed.create(aliasName: backedupWallet.name,
                                                            type: backedupWallet.type,
                                                            mnemonicsEthereum: privateKeyOrSeed)
        }
    }
    
    func getPrivateKeyThrowing() throws -> String {
        guard let privateKey = getPrivateKey() else { throw Error.failedToRetrievePK }
        
        return privateKey
    }
    
    func getPrivateKey() -> String? {
        guard let ethWallet = self.ethWallet else { return nil }
        switch ethWallet.securityType {
        case .normal: return KeychainPrivateKeyStorage.instance.retrievePrivateKey(for: ethWallet.address)
        case .hd: if let privKeyShortcut = getKeyShortcut(for: ethWallet.address) { return privKeyShortcut }
            guard let (_, privateKey) = try? ethWallet.exportHD() else {
                Debugger.printFailure("Cannot get PK for wallet \(self.aliasName) \(self.getActiveAddress(for: .UNS) ?? "address n/a")", critical: true)
                return nil }
            saveKeyShortcut(address: ethWallet.address, privateKey: privateKey)
            return privateKey
        case .undefined: return nil
        }
    }
    
    func getMnemonicsThrowing() throws -> String {
        guard let mnemonics = getMnemonics() else { throw Error.failedToRetrieveSP }
        
        return mnemonics
    }
    
    func getMnemonics() -> String? {
        guard let ethWallet = self.ethWallet else { return nil }
        switch ethWallet.securityType {
        case .normal: return nil
        case .hd: return KeychainPrivateKeyStorage.instance.retrievePrivateKey(for: ethWallet.address)
        case .undefined: return nil
        }
    }
    
    static func createUnverified(aliasName: String? = nil,
                                 address: HexAddress) -> UDWallet? {
        let name = aliasName == nil ? address : aliasName!
        let wallet = UDWalletEthereum.createUnverified(address: address)
        return UDWallet(aliasName: name,
                        walletType: .importedUnverified,
                        ethWallet: wallet)
    }
    
    static func createLinked(aliasName: String,
                             address: String,
                             externalWallet: WCWalletsProvider.WalletRecord) -> UDWallet {
        let ethWallet = UDWalletEthereum.createUnverified(address: address)
        var udWallet = UDWallet(aliasName: aliasName,
                                walletType: .externalLinked,
                                ethWallet: ethWallet)
        udWallet.walletConnectionInfo = UDWallet.WalletConnectionInfo(externalWallet: externalWallet)
        
        return udWallet
    }
    
    static func create(aliasName: String) async throws -> UDWallet {
        guard let wrappedWallet = try? UDWalletEthereum.createHDWallet(name: aliasName,
                                                                       type: .generatedLocally) else {
            throw WalletError.EthWalletFailedInit
        }
        
        let mnemonics = wrappedWallet.privateSeed
        let generatedWallet: UDWallet = try await UDWallet.create(aliasName: aliasName,
                                                                  walletType: .generatedLocally,
                                                                  mnemonicsEthereum: mnemonics)
        return generatedWallet
    }
    
    static func createEmpty(aliasName: String) -> UDWallet {
        let generatedWallet = UDWallet(aliasName: aliasName,
                                       walletType: .generatedLocally,
                                       ethWallet: nil)
        return generatedWallet
    }
    
    
    static func create (aliasName: String,
                        walletType: WalletType,
                        mnemonicsEthereum: String,
                        hasBeenBackedUp: Bool = false) async throws -> UDWallet {
        let wrappedWallet: UDWalletEthereumWithPrivateSeed
        let privateKeyEthereum: String
        do {
            wrappedWallet = try UDWalletEthereum.createVerified(mnemonics: mnemonicsEthereum)
            privateKeyEthereum = try wrappedWallet.getPrivateKey()
        } catch {
            Debugger.printFailure("Failed to init UDWalletEthereum with mnemonics", critical: false)
            throw error
        }
        
        return try create(with: wrappedWallet,
                                aliasName: aliasName,
                                privateKeyEthereum: privateKeyEthereum,
                                walletType: walletType,
                                hasBeenBackedUp: hasBeenBackedUp)
    }
    
    static func create(aliasName: String,
                       walletType: WalletType,
                       privateKeyEthereum: String,
                       hasBeenBackedUp: Bool = false) async throws -> UDWallet {
        let wrappedWallet: UDWalletEthereumWithPrivateSeed
        do {
            wrappedWallet = try UDWalletEthereum.createVerified(privateKey: privateKeyEthereum)
        } catch {
            Debugger.printFailure("Failed to init UDWalletEthereum with priv key", critical: false)
            throw error
        }
        
        return try create(with: wrappedWallet,
                                aliasName: aliasName,
                                
                                privateKeyEthereum: privateKeyEthereum,
                                walletType: walletType,
                                hasBeenBackedUp: hasBeenBackedUp)
    }
    
    static private func create(with wrappedWallet: UDWalletEthereumWithPrivateSeed,
                               aliasName: String,
                               privateKeyEthereum: String,
                               walletType: WalletType,
                               hasBeenBackedUp: Bool = false) throws -> UDWallet {
        let address = wrappedWallet.ethWallet.address
        guard !UDWalletsStorage.instance.doesWalletExist(address: address, namingService: .UNS) else {
            throw WalletError.ethWalletAlreadyExists(address)
        }
        
        let privateSeedString: String = wrappedWallet.privateSeed
        KeychainPrivateKeyStorage.instance.store(privateKey: privateSeedString, for: address)
        
        let udWallet: UDWallet = Self.create(aliasName: aliasName,
                                             walletType: walletType,
                                             ethWallet: wrappedWallet.ethWallet,
                                             hasBeenBackedUp: hasBeenBackedUp)
        return udWallet
    }
    
    static func create(aliasName: String,
                       walletType: WalletType,
                       ethWallet: UDWalletEthereum,
                       hasBeenBackedUp: Bool = false) -> UDWallet {
        return UDWallet(aliasName: aliasName,
                        walletType: walletType,
                        ethWallet: ethWallet,
                        hasBeenBackedUp: hasBeenBackedUp)
    }
    
    static func createMPC(address: String,
                          aliasName: String,
                          mpcMetadata: MPCWalletMetadata) -> UDWallet {
        let ethWallet = UDWalletEthereum.createUnverified(address: address)
        
        var udWallet = UDWallet(aliasName: aliasName,
                                walletType: .mpc,
                                ethWallet: ethWallet)
        udWallet.mpcMetadata = mpcMetadata
        
        return udWallet
    }
    
    func getAddress(for namingService: NamingService) -> String? {
        switch namingService {
        case .UNS: return self.extractEthWallet()?.address
        }
    }
        
    func setNameAsAddress() -> UDWallet {
        var _wallet = self
        _wallet.aliasName = self.getActiveAddress(for: .UNS) ?? "Wallet"
        return _wallet
    }
    
    mutating func mutateNameToAddress() {
        aliasName = self.getActiveAddress(for: .UNS) ?? "Wallet"
    }
    
    func isAlreadyConnected() -> Bool {
        UDWalletsStorage.instance.doesExist(udWallet: self)
    }
    
    func extractEthWallet() -> UDWalletEthereum? {
        return ethWallet
    }
    
    func extractMPCMetadata() throws -> MPCWalletMetadata {
        guard let mpcMetadata else { throw UDWallet.Error.failedToFindMPCMetadata }

        return mpcMetadata
    }
}

extension UDWallet {
    // MARK: Shortcut storage for private keys
    // ONLY FOR DEBUG MODE
    
#if DEBUG
    static var shortcutKeyStorage: [String: String] = [:]
#endif
    
    private func getKeyShortcut(for address: String) -> String? {
#if DEBUG
        return Self.shortcutKeyStorage[address]
#else
        return nil
#endif
    }
    
    private func saveKeyShortcut(address: String, privateKey: String) {
#if DEBUG
        Self.shortcutKeyStorage[address] = privateKey
#else
        return
#endif
    }
}

extension Array where Element == UDWallet {
    func pickOwnedDomains(from domains: [DomainItem]) -> [DomainItem] {
        let ethWalletAddresses = self.compactMap({$0.extractEthWallet()?.address.normalized})
        let selected = domains.filter {
            guard let ownerWallet = $0.ownerWallet else { return false }
            return ethWalletAddresses.contains(ownerWallet.normalized)
        }
        return selected
    }
    
    func pickOwnedDomains(from domains: [DomainItem],
                          in namingService: NamingService) -> [DomainItem] {
        var walletAddresses: [HexAddress] = []
        switch namingService {
        case .UNS:
            walletAddresses = self.compactMap({$0.extractEthWallet()?.address.normalized})
        }
        let selected = domains.filter {
            guard let ownerWallet = $0.ownerWallet else { return false }
            return walletAddresses.contains(ownerWallet.normalized)
        }
        return selected
    }
}

extension UDWallet {
    func owns(domain: any DomainEntity) -> Bool {
        guard let domainWalletAddress = domain.ownerWallet?.normalized else { return false }
        return self.address.normalized == domainWalletAddress || self.address.normalized == domainWalletAddress
    }
    
    func getActiveAddress(for namingService: NamingService) -> String? {
        let etereumStyleAddress = self.extractEthWallet()?.address.normalized
        
        switch namingService {
        case .UNS: return etereumStyleAddress
        }
    }
    
    var address: String { getActiveAddress(for: .UNS) ?? "" }
}

extension UDWallet {    
    func getExternalWallet() -> WCWalletsProvider.WalletRecord? {
        walletConnectionInfo?.externalWallet
    }
    
    
    func getExternalWalletName() -> String? {
        walletConnectionInfo?.externalWallet.name
    }
    
    var isExternalConnectionActive: Bool {
        !(WCClientConnectionsV2.shared.findSessions(by: self.address).isEmpty)
    }
}

extension UDWallet: Equatable {
    static func == (lhs: UDWallet, rhs: UDWallet) -> Bool {
        let resultEth = (lhs.extractEthWallet()?.address == rhs.extractEthWallet()?.address) && lhs.extractEthWallet()?.address != nil
        return resultEth
    }
}

extension UDWallet: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.address)
        hasher.combine(self.aliasName)
        hasher.combine(self.hasBeenBackedUp)
        hasher.combine(self.type)
    }
}
