//
//  LegacyUnitaryWallet.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 24.08.2021.
//

//import Foundation
//import web3swift
//
//// Legacy
//
//struct LegacyWalletStorage {
//    private init() {}
//    static var instance = LegacyWalletStorage()
//    private var walletsStorage = SpecificStorage<[LegacyUnitaryWallet]>(fileName: Storage.Files.walletsStorage.fileName)
//    let walletsWorkerQueue = DispatchQueue(label: "legacyUnitaryWalletsWorkerQueue")
//    
//    func getWalletsList(ownedBy userId: Int) -> [LegacyUnitaryWallet]? {
//        return walletsStorage.retrieve()
//    }
//    
//    func remove() {
//        walletsStorage.remove()
//    }
//}
//
//struct LegacyUnitaryWallet: Codable {
//    enum SecurityType: Int, Codable {
//        case normal
//        case hd
//    }
//    
//    static let legacyPersistedDefaultWalletKey = "persisted-ud-app-wallet"
//    
//    var address: String
//    var aliasName: String = ""
//    var domains: [DomainItem] = []
//    var type: WalletType
//    let securityType: SecurityType
//    
//    private init(address: HexAddress, aliasName: String, domains: [DomainItem] = [], type: WalletType, securityType: SecurityType) {
//        self.address = address
//        self.aliasName = aliasName
//        self.domains = domains
//        self.type = type
//        self.securityType = securityType
//    }
//}
//
//extension LegacyUnitaryWallet {
//    func convertToUDWallet() async throws -> UDWallet {
//        switch self.securityType {
//        case .normal:
//            guard let privateKeyEthereum = self.getPrivateKey() else {
//                Debugger.printFailure("Failed to find priv key for wallet: \(self.address)", critical: true)
//                throw WalletError.EthWalletPrivateKeyNotFound
//            }
//            return try await UDWallet.create(aliasName: self.aliasName,
//                                             walletType: self.type,
//                                             privateKeyEthereum: privateKeyEthereum)
//        case .hd:
//            guard let mnemonicsEthereum = self.getMnemonicsArray()?.mnemonicsString else {
//                Debugger.printFailure("Failed to find mnemonics for wallet: \(self.address)", critical: true)
//                throw WalletError.EthWalletPrivateKeyNotFound
//            }
//            return try await UDWallet.create(aliasName: self.aliasName,
//                                             walletType: self.type,
//                                             mnemonicsEthereum: mnemonicsEthereum)
//        }
//    }
//}
//
//extension LegacyUnitaryWallet {
//    enum Web3ServiceError: Error {
//        case err
//        case noKeyStore
//        case noAddress
//    }
//    
//    static let twelveWordEnthropy = 128
//    static let wordsSeparator: Character = " "
//    static let passwordString = "password"
//    
//    func getPrivateKey() -> String? {
//        guard self.securityType == .normal else {
//            guard let (_, privateKey) = try? self.exportHD() else {
//                return nil
//            }
//            return privateKey
//        }
//        return KeychainPrivateKeyStorage.instance.retrievePrivateKey(for: address)
//    }
//    
//    func exportHD() throws -> (mnemonics: [String], privateKey: String) {
//        guard .hd == self.securityType else { throw Web3ServiceError.err  }
//        let keyStoreManager = try fetchKeyStoreManager(wallet: self)
//        guard let ethereumAddress = EthereumAddress(self.address) else { throw Web3ServiceError.noAddress }
//        let key = try keyStoreManager.UNSAFE_getPrivateKeyData(password: Self.passwordString,
//                                                               account: ethereumAddress).dataToHexString()
//        guard let mnemArray = self.getMnemonicsArray() else { throw Web3ServiceError.err }
//        return (mnemonics: mnemArray, privateKey: key)
//    }
//    
//    func fetchKeyStoreManager(wallet: LegacyUnitaryWallet) throws -> KeystoreManager {
//        guard .hd == wallet.securityType else { throw Web3ServiceError.err }
//        guard let mnemArray = wallet.getMnemonicsArray() else { throw Web3ServiceError.err }
//        let data = try getKeyData(by: mnemArray.mnemonicsString)
//        guard let keystore = BIP32Keystore(data) else { throw Web3ServiceError.noKeyStore }
//        return KeystoreManager([keystore])
//    }
//    
//    func getKeyData(by mnemonicsString: String) throws -> Data {
//        guard let keystore = try BIP32Keystore(mnemonics: mnemonicsString,
//                                               password: Self.passwordString,
//                                               mnemonicsPassword: "",
//                                               language: Self.getBIPLanguage()) else { throw Web3ServiceError.err }
//        return try JSONEncoder().encode(keystore.keystoreParams)
//    }
//    
//    func getMnemonicsArray() -> [String]? {
//        guard self.securityType == .hd else {
//            Debugger.printFailure("wrong type", critical: true)
//            return nil
//        }
//        if let string = KeychainPrivateKeyStorage.instance.retrievePrivateKey(for: address) {
//            return string.mnemonicsArray
//        }
//        return nil
//    }
//    
//    static func getBIPLanguage() -> BIP39Language {
//        return .english
//        
//        /*
//        guard let lang = Locale.current.languageCode else { return .english }
//        switch lang.lowercased() {
//        case "en": return .english
//        case "es": return .spanish
//        case "zh": return .chinese_simplified
//        default: return .english
//        }
//         */
//    }
//}
