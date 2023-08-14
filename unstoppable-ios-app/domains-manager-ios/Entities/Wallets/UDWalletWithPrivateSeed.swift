//
//  UDWalletWithPrivateSeed.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.01.2023.
//

import Foundation

// UDWallet that has its private key as a property, not in the keychain
struct UDWalletWithPrivateSeed {
    let udWallet: UDWallet
    let privateSeed: String
    
    func saveSeedToKeychain() throws -> UDWallet {
        guard let address = self.udWallet.ethWallet?.address else {
            throw WalletError.ethWalletNil
        }
        guard !UDWalletsStorage.instance.doesWalletExist(address: address, namingService: .UNS) else {
            throw WalletError.ethWalletAlreadyExists(address)
        }
        let privateSeedString: String = self.privateSeed
        KeychainPrivateKeyStorage.instance.store(privateKey: privateSeedString, for: address)
        
        return self.udWallet
    }
    
    static func create(aliasName: String,
                       type: WalletType,
                       mnemonicsEthereum: String,
                       hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        let privateKeyEthereum: String
        let wrappedWallet: UDWalletEthereumWithPrivateSeed
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
                       hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
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
    
    static func createWithoutZil(aliasName: String,
                                 type: WalletType,
                                 mnemonicsEthereum: String,
                                 hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        let wrappedWallet: UDWalletEthereumWithPrivateSeed
        do {
            wrappedWallet = try UDWalletEthereum.createVerified(mnemonics: mnemonicsEthereum)
        } catch {
            Debugger.printFailure("Failed to init UDWalletEthereum with mnemonics", critical: false)
            throw error
        }
        
        let udWallet = UDWallet.create(aliasName: aliasName,
                                       type: type,
                                       ethWallet: wrappedWallet.ethWallet,
                                       zilWallet: nil,
                                       hasBeenBackedUp: hasBeenBackedUp)
        return UDWalletWithPrivateSeed(udWallet: udWallet, privateSeed: wrappedWallet.privateSeed)
    }
    
    static func createWithoutZil(aliasName: String,
                                 type: WalletType,
                                 privateKeyEthereum: String,
                                 hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        let wrappedWallet: UDWalletEthereumWithPrivateSeed
        do {
            wrappedWallet = try UDWalletEthereum.createVerified(privateKey: privateKeyEthereum)
        } catch {
            Debugger.printFailure("Failed to init UDWalletEthereum with priv key", critical: false)
            throw error
        }
        
        let udWallet = UDWallet.create(aliasName: aliasName,
                                       type: type,
                                       ethWallet: wrappedWallet.ethWallet,
                                       zilWallet: nil,
                                       hasBeenBackedUp: hasBeenBackedUp)
        return UDWalletWithPrivateSeed(udWallet: udWallet, privateSeed: wrappedWallet.privateSeed)
    }
    
    static private func create(with wrappedEthereumWallet: UDWalletEthereumWithPrivateSeed,
                               aliasName: String,
                                                  privateKeyEthereum: String,
                                                  type: WalletType,
                                                  hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        
        return try await withSafeCheckedThrowingContinuation { completion in
            UDWalletZil.create(privateKey: privateKeyEthereum) { zil in
                guard let zilWallet = zil else {
                    Debugger.printFailure("Failed to init UDWalletZil with priv key", critical: true)
                    completion(.failure(WalletError.zilWalletFailedInit))
                    return
                }
                let udWallet = UDWallet.create(aliasName: aliasName,
                                                  type: type,
                                                  ethWallet: wrappedEthereumWallet.ethWallet,
                                                  zilWallet: zilWallet,
                                                  hasBeenBackedUp: hasBeenBackedUp)
                completion(.success(UDWalletWithPrivateSeed(udWallet: udWallet, privateSeed: wrappedEthereumWallet.privateSeed)))
            }
        }
    }
}
