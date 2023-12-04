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

struct WalletIconSpec {
    let imageName: String
    var hue: Float? = nil
    var saturation: Float? = nil
}

// How it was generated
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

enum WalletState: String, Codable {
    case verified // private key, seed phrase
    case externalLinked // external wallet. Read only
}

protocol AddressContainer {
    var address: String { get }
}



struct UDWallet: Codable {
    enum Error: String, Swift.Error, RawValueLocalizable {
        case failedToSignMessage = "Failed to Sign Message"
        case noWalletOwner = "No Owner Wallet Specified"
        case failedToFindWallet = "Failed to Find a Wallet"
        case zilNotSupported = "Zilliqua not supported"
        case failedSignature
    }
    
    struct WalletConnectionInfo: Codable {
        var externalWallet: WCWalletsProvider.WalletRecord
    }
    
    var aliasName: String
    var type: WalletType
    var ethWallet: UDWalletEthereum?
    var zilWallet: UDWalletZil?
    var hasBeenBackedUp: Bool? = false
    
    var walletState: WalletState {
        return self.isExternalConnectionActive ? .externalLinked : .verified
    }
    
    var isMintingHost: Bool {
        return walletState == .verified || walletState == .externalLinked
    }
    
    private var walletConnectionInfo: WalletConnectionInfo?
    
    private init(aliasName: String,
                 type: WalletType,
                 ethWallet: UDWalletEthereum?,
                 zilWallet: UDWalletZil?,
                 hasBeenBackedUp: Bool = false) {
        self.aliasName = aliasName
        self.type = type
        self.ethWallet = ethWallet
        self.zilWallet = zilWallet
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
    
    func getMnemonics() -> String? {
        guard let ethWallet = self.ethWallet else { return nil }
        switch ethWallet.securityType {
        case .normal: return nil
        case .hd: return KeychainPrivateKeyStorage.instance.retrievePrivateKey(for: ethWallet.address)
        case .undefined: return nil
        }
    }
    
    static func createUnverified(response: NetworkService.TxCryptoWalletResponse) -> UDWallet? {
        let aliasName = response.humanAddress
        guard let type = try? BlockchainType.getType(abbreviation: response.blockchain) else {
            return nil
        }
        
        switch type {
        case .Ethereum, .Matic: let wallet = UDWalletEthereum.createUnverified(address: response.address)
            return UDWallet(aliasName: aliasName,
                            type: .importedUnverified,
                            ethWallet: wallet,
                            zilWallet: nil)
        case .Zilliqa: let wallet = UDWalletZil.createUnverified(address: response.address, humanAddress: response.humanAddress)
            return UDWallet(aliasName: aliasName,
                            type: .importedUnverified,
                            ethWallet: nil,
                            zilWallet: wallet)
        }
    }
    
    static func createUnverified(aliasName: String? = nil,
                                 address: HexAddress) -> UDWallet? {
        let name = aliasName == nil ? address : aliasName!
        let wallet = UDWalletEthereum.createUnverified(address: address)
        return UDWallet(aliasName: name,
                        type: .importedUnverified,
                        ethWallet: wallet,
                        zilWallet: nil)
    }
    
    static func createLinked(aliasName: String,
                             address: String,
                             externalWallet: WCWalletsProvider.WalletRecord) -> UDWallet {
        let ethWallet = UDWalletEthereum.createUnverified(address: address)
        var udWallet = UDWallet(aliasName: aliasName,
                                type: .importedUnverified,
                                ethWallet: ethWallet,
                                zilWallet: nil)
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
                                                                  type: .generatedLocally,
                                                                  mnemonicsEthereum: mnemonics)
        return generatedWallet
    }
    
    static func createEmpty(aliasName: String) -> UDWallet {
        let generatedWallet = UDWallet(aliasName: aliasName,
                                       type: .generatedLocally,
                                       ethWallet: nil,
                                       zilWallet: nil)
        return generatedWallet
    }
    
    
    static func create (aliasName: String,
                        type: WalletType,
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
        
        return try await create(with: wrappedWallet,
                                aliasName: aliasName,
                                privateKeyEthereum: privateKeyEthereum,
                                type: type,
                                hasBeenBackedUp: hasBeenBackedUp)
    }
    
    static func create(aliasName: String,
                       type: WalletType,
                       privateKeyEthereum: String,
                       hasBeenBackedUp: Bool = false) async throws -> UDWallet {
        let wrappedWallet: UDWalletEthereumWithPrivateSeed
        do {
            wrappedWallet = try UDWalletEthereum.createVerified(privateKey: privateKeyEthereum)
        } catch {
            Debugger.printFailure("Failed to init UDWalletEthereum with priv key", critical: false)
            throw error
        }
        
        return try await create(with: wrappedWallet,
                                aliasName: aliasName,
                                
                                privateKeyEthereum: privateKeyEthereum,
                                type: type,
                                hasBeenBackedUp: hasBeenBackedUp)
    }
    
    static private func create(with wrappedWallet: UDWalletEthereumWithPrivateSeed,
                               aliasName: String,
                               privateKeyEthereum: String,
                               type: WalletType,
                               hasBeenBackedUp: Bool = false) async throws -> UDWallet {
        let address = wrappedWallet.ethWallet.address
        guard !UDWalletsStorage.instance.doesWalletExist(address: address, namingService: .UNS) else {
            throw WalletError.ethWalletAlreadyExists(address)
        }
        return try await withSafeCheckedThrowingContinuation { completion in
            
            UDWalletZil.create(privateKey: privateKeyEthereum) { zil in
                guard let zilWallet = zil else {
                    Debugger.printFailure("Failed to init UDWalletZil with priv key", critical: true)
                    completion(.failure(WalletError.zilWalletFailedInit))
                    return
                }
                
                // all checks done, 2 subwallets created -- storing to Keychain
                let privateSeedString: String = wrappedWallet.privateSeed
                KeychainPrivateKeyStorage.instance.store(privateKey: privateSeedString, for: address)
                
                let udWallet: UDWallet = Self.create(aliasName: aliasName,
                                                     type: type,
                                                     ethWallet: wrappedWallet.ethWallet,
                                                     zilWallet: zilWallet,
                                                     hasBeenBackedUp: hasBeenBackedUp)
                completion(.success(udWallet))
            }
        }
    }
    
    static func create(aliasName: String,
                       type: WalletType,
                       ethWallet: UDWalletEthereum,
                       zilWallet: UDWalletZil?,
                       hasBeenBackedUp: Bool = false) -> UDWallet {
        return UDWallet(aliasName: aliasName,
                        type: type,
                        ethWallet: ethWallet,
                        zilWallet: zilWallet,
                        hasBeenBackedUp: hasBeenBackedUp)
    }
    
    func getAddress(for namingService: NamingService) -> String? {
        switch namingService {
        case .UNS: return self.extractEthWallet()?.address
        case .ZNS: return self.extractZilWallet()?.address
        }
    }
    
    static func create (aliasName: String,
                        type: WalletType,
                        keyStoreZil: String,
                        encryptionPassword: String) async throws -> UDWallet {
        return try await withSafeCheckedThrowingContinuation { completion in
            UDWalletZil.create(keystoreJson: keyStoreZil,
                               encryptionPassword: encryptionPassword) { zil, prKey in
                guard let zilWallet = zil,
                      let privateKey = prKey else {
                    completion(.failure(WalletZilError.failedToRestoreFromJson))
                    return
                }
                let privateKeyEthereum = privateKey
                let wrappedWallet: UDWalletEthereumWithPrivateSeed
                
                do { wrappedWallet = try UDWalletEthereum.createVerified(privateKey: privateKeyEthereum) } catch {
                    completion(.failure(WalletError.EthWalletFailedInit))
                    return
                }
                
                let address = wrappedWallet.ethWallet.address
                guard !UDWalletsStorage.instance.doesWalletExist(address: address, namingService: .UNS) else {
                    completion(.failure(WalletError.ethWalletAlreadyExists(address)))
                    return
                }
                
                let privateSeedString: String = wrappedWallet.privateSeed
                KeychainPrivateKeyStorage.instance.store(privateKey: privateSeedString, for: address)
                
                let udWallet = UDWallet(aliasName: aliasName,
                                        type: type,
                                        ethWallet: wrappedWallet.ethWallet,
                                        zilWallet: zilWallet)
                completion(.success(udWallet))
            }
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
    
    func extractZilWallet() -> UDWalletZil? {
        return zilWallet
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

enum WalletError: Error {
    case NameTooShort
    case WalletNameNotUnique
    case EthWalletFailedInit
    case EthWalletPrivateKeyNotFound
    case EthWalletMnemonicsNotFound
    case zilWalletFailedInit
    case migrationError
    case failedGetPrivateKeyFromNonHdWallet
    case ethWalletAlreadyExists (HexAddress)
    case invalidPrivateKey
    case invalidSeedPhrase
    case importedWalletWithoutUNS
    case ethWalletNil
    case unsupportedBlockchainType
    
    case failedToBackUp
    case incorrectBackupPassword
}

extension Array where Element == UDWallet {
    func pickOwnedDomains(from domains: [DomainItem]) -> [DomainItem] {
        let ethWalletAddresses = self.compactMap({$0.extractEthWallet()?.address.normalized})
        let zilWalletAddresses = self.compactMap({$0.extractZilWallet()?.address.normalized})
        let walletAddresses = ethWalletAddresses + zilWalletAddresses
        let selected = domains.filter {
            guard let ownerWallet = $0.ownerWallet else { return false }
            return walletAddresses.contains(ownerWallet.normalized)
        }
        return selected
    }
    
    func pickOwnedDomains(from domains: [DomainItem],
                          in namingService: NamingService) -> [DomainItem] {
        var walletAddresses: [HexAddress] = []
        switch namingService {
        case .UNS:
            walletAddresses = self.compactMap({$0.extractEthWallet()?.address.normalized})
        case .ZNS:
            walletAddresses = self.compactMap({$0.extractZilWallet()?.address.normalized})
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
    
    var activeZilAddress: String? {
        switch UDWalletZil.network {
        case .mainnet: return self.extractZilWallet()?.bech32addressMainnet
        case .testnet: return self.extractZilWallet()?.bech32addressTestnet
        }
    }
    
    func getActiveAddress(for namingService: NamingService) -> String? {
        let etereumStyleAddress = self.extractEthWallet()?.address.normalized
        
        switch namingService {
        case .UNS: return etereumStyleAddress
        case .ZNS: return self.activeZilAddress
        }
    }
    
    var address: String { getActiveAddress(for: .UNS) ?? "" }
}

extension UDWallet {
    func launchExternalWallet() async throws {
        guard let wcWallet = self.walletConnectionInfo?.externalWallet,
              let  nativePrefix = wcWallet.getNativeAppLink(),
              let url = URL(string: nativePrefix) else {
            throw WalletConnectRequestError.failedToFindExternalAppLink
        }
        
        try await withCheckedThrowingContinuation { (completion: CheckedContinuation<Void, Swift.Error>) in
            DispatchQueue.main.async {
                guard UIApplication.shared.canOpenURL(url) else {
                    completion.resume(throwing: WalletConnectRequestError.failedOpenExternalApp)
                    return
                }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                completion.resume(returning: ())
            }
        }
    }
    
    func getExternalWallet() -> WCWalletsProvider.WalletRecord? {
        walletConnectionInfo?.externalWallet
    }
    
    
    func getExternalWalletName() -> String? {
        walletConnectionInfo?.externalWallet.name
    }
    
    var isExternalConnectionActive: Bool {
        !(appContext.walletConnectServiceV2.findSessions(by: self.address).isEmpty)
    }
}

extension UDWallet: Equatable {
    static func == (lhs: UDWallet, rhs: UDWallet) -> Bool {
        let resultEth = (lhs.extractEthWallet()?.address == rhs.extractEthWallet()?.address) && lhs.extractEthWallet()?.address != nil
        let resultZil = (lhs.extractZilWallet()?.address == rhs.extractZilWallet()?.address) && lhs.extractZilWallet()?.address != nil
        return resultEth || resultZil
    }
}

protocol WalletConnectController: UIViewController {
    func warnManualTransferToExternalWallet(title: String)
}

extension WalletConnectController {
    func warnManualTransferToExternalWallet(title: String) {
        self.showSimpleAlert(title: title, body: "Please switch to the external wallet app manually, confirm to sign the transaction and return back")
    }
}

extension UDWallet {
    var recoveryType: RecoveryType? {
        .init(walletType: type)
    }
    
    enum RecoveryType: Codable {
        case recoveryPhrase
        case privateKey
        
        init?(walletType: WalletType) {
            switch walletType {
            case .privateKeyEntered:
                self = .privateKey
            case .defaultGeneratedLocally, .generatedLocally, .mnemonicsEntered:
                self = .recoveryPhrase
            case .importedUnverified:
                return nil
            }
        }
    }
}
