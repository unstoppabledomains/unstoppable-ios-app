//
//  UDWalletEthereum.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 18.03.2021.
//

import Foundation
import web3swift
import CryptoSwift
import Boilertalk_Web3

struct UDWalletEthereumWithPrivateSeed {
    let ethWallet: UDWalletEthereum
    let privateSeed: String
    
    func getPrivateKey() throws -> String {
        guard .hd == self.ethWallet.securityType else { throw WalletError.failedGetPrivateKeyFromNonHdWallet  }
        let keyStoreManager = try UDWalletEthereum.fetchKeyStoreManager(wrappedWallet: self)
        guard let ethereumAddress = EthereumAddress(self.ethWallet.address) else { throw UDWalletEthereum.Web3SwiftError.noAddress }
        let key = try keyStoreManager.UNSAFE_getPrivateKeyData(password: UDWalletEthereum.passwordString,
                                                               account: ethereumAddress).toHexString()
        return key
    }
}

class UDWalletEthereum: AddressContainer, Codable {
    enum SecurityType: Int, Codable {
        case normal
        case hd
        case undefined
    }

    var address: String
    var securityType: SecurityType
    var hasPrivateKey: Bool?
    
    static let passwordString = "password"
        
    private init(address: HexAddress, securityType: SecurityType) {
        self.address = address
        self.hasPrivateKey = false
        self.securityType = securityType
    }
    
    convenience private init(address: String) {
        self.init(address: address, securityType: .undefined)
    }
    
    static func createUnverified(address: String) -> UDWalletEthereum {
        let wallet = UDWalletEthereum(address: address, securityType: .undefined)
        wallet.hasPrivateKey = false
        return wallet
    }

    static func createVerified(privateKey: String) throws -> UDWalletEthereumWithPrivateSeed {
        let address =  try Self.generateAddress(privateKeyString: privateKey)
        return createVerifiedWithPrivateSeed(by: address, privateSeedString: privateKey, walletType: .normal)
    }
    
    static func createVerified(mnemonics: String) throws -> UDWalletEthereumWithPrivateSeed {
        let address = try Self.generateAddress(by: mnemonics)
        return createVerifiedWithPrivateSeed(by: address, privateSeedString: mnemonics, walletType: .hd)
    }
    
    static private func createVerifiedWithPrivateSeed(by address: HexAddress,
                                       privateSeedString: String,
                                       walletType: SecurityType) -> UDWalletEthereumWithPrivateSeed {
        let wallet = UDWalletEthereum(address: address, securityType: walletType)
        wallet.hasPrivateKey = true
        return UDWalletEthereumWithPrivateSeed(ethWallet: wallet, privateSeed: privateSeedString)
    }
}

// MARK: Ethereum address computation
extension UDWalletEthereum {
    static func generateAddress(privateKeyString: String) throws -> String {
        guard let pK = try? EthereumPrivateKey(hexPrivateKey: privateKeyString) else {
            throw Web3SwiftError.failedGenerateEthereumPrivateKey
        }
        return generateAddress(privateKey: pK)
    }
    
    static func generateAddress(by mnemonicsString: String) throws -> String {
        guard let keystore = try BIP32Keystore(mnemonics: mnemonicsString,
                                               password: Self.passwordString,
                                               mnemonicsPassword: "",
                                               language: Self.getBIPLanguage()) else { throw Web3SwiftError.noKeyStore }
        guard let address = keystore.addresses?.first?.address else { throw Web3SwiftError.noAddress }
        return address
    }
    
    private static func generateAddress(privateKey: EthereumPrivateKey) -> String {
        let pubKey = privateKey.address
        return pubKey.hex(eip55: true)
    }
    
    private static func getBIPLanguage() -> BIP39Language {
        return .english
        /*
        // This code may be used IF and WHEN all major wallets switch to localized seed phrase
         
        guard let lang = Locale.current.languageCode else { return .english }
        switch lang.lowercased() {
        case "en": return .english
        case "es": return .spanish
        case "zh": return .chinese_simplified
        default: return .english
        }
         */
    }
}

// Ethereum cryptography -- web3swift lib
extension UDWalletEthereum {
    static let twelveWordEnthropy = 128
    static let wordsSeparator: Character = " "

    enum Web3SwiftError: String, LocalizedError {
        case err
        case noKeyStore
        case noAddress
        case failedGenerateMnemonics
        case failedGenerateEthereumPrivateKey
        
        public var errorDescription: String? {
            return rawValue
        }
    }
        
    static func createHDWallet(name: String, type: WalletType = .generatedLocally) throws -> UDWalletEthereumWithPrivateSeed {
        guard let mnemonicsString = try BIP39.generateMnemonics(bitsOfEntropy: Self.twelveWordEnthropy,
                                                                language: Self.getBIPLanguage()) else {
            throw Web3SwiftError.failedGenerateMnemonics }
        let ethWallet = try UDWalletEthereum.createVerified(mnemonics: mnemonicsString)
        return ethWallet
    }
    
    func exportHD() throws -> (mnemonics: [String], privateKey: String) {
        guard .hd == self.securityType else { throw WalletError.failedGetPrivateKeyFromNonHdWallet  }
        let keyStoreManager = try Self.fetchKeyStoreManager(wallet: self)
        guard let ethereumAddress = EthereumAddress(self.address) else { throw Web3SwiftError.noAddress }
        let key = try keyStoreManager.UNSAFE_getPrivateKeyData(password: Self.passwordString,
                                                               account: ethereumAddress).toHexString()
        guard let mnemArray = self.getMnemonicsArray() else { throw WalletError.EthWalletMnemonicsNotFound }
        return (mnemonics: mnemArray, privateKey: key)
    }
    
    static func fetchKeyStoreManager(wallet: UDWalletEthereum) throws -> KeystoreManager {
        guard .hd == wallet.securityType else { throw WalletError.failedGetPrivateKeyFromNonHdWallet }
        guard let mnemArray = wallet.getMnemonicsArray() else { throw WalletError.EthWalletMnemonicsNotFound }
        let data = try getKeyData(by: mnemArray.mnemonicsString)
        guard let keystore = BIP32Keystore(data) else { throw Web3SwiftError.noKeyStore }
        return KeystoreManager([keystore])
    }
    
    static func fetchKeyStoreManager(wrappedWallet: UDWalletEthereumWithPrivateSeed) throws -> KeystoreManager {
        guard .hd == wrappedWallet.ethWallet.securityType else { throw WalletError.failedGetPrivateKeyFromNonHdWallet }
        let mnemonics = wrappedWallet.privateSeed
        let data = try getKeyData(by: mnemonics)
        guard let keystore = BIP32Keystore(data) else { throw Web3SwiftError.noKeyStore }
        return KeystoreManager([keystore])
    }
    
    func getMnemonicsArray() -> [String]? {
        guard self.securityType == .hd else {
            Debugger.printFailure("wrong type", critical: true)
            return nil
        }
        if let string = KeychainPrivateKeyStorage.instance.retrievePrivateKey(for: address) {
            return string.mnemonicsArray
        }
        return nil
    }
    
    static func getKeyData(by mnemonicsString: String) throws -> Data {
        guard let keystore = try BIP32Keystore(mnemonics: mnemonicsString,
                                               password: Self.passwordString,
                                               mnemonicsPassword: "",
                                               language: Self.getBIPLanguage()) else { throw Web3SwiftError.noKeyStore }
        return try JSONEncoder().encode(keystore.keystoreParams)
    }
}

extension Array where Element == String {
    static let blank = " "
    var mnemonicsString: String {
        self.joined(separator: Self.blank)
    }
}

extension String {
    static let blank: Character = " "
    var mnemonicsArray: [String] {
        self.split(separator: Self.blank).map(String.init)
    }
}
