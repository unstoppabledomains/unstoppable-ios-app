//
//  UDWalletWithPrivateSeed.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.01.2023.
//

import Foundation
import PromiseKit

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
                        hasBeenBackedUp: Bool = false) -> Promise<UDWalletWithPrivateSeed> {
        return Promise { seal in
            let privateKeyEthereum: String
            let wrappedWallet: UDWalletEthereumWithPrivateSeed
            do {
                wrappedWallet = try UDWalletEthereum.createVerified(mnemonics: mnemonicsEthereum)
                privateKeyEthereum = try wrappedWallet.getPrivateKey()
            } catch {
                Debugger.printFailure("Failed to init UDWalletEthereum with mnemonics", critical: false)
                seal.reject(error)
                return
            }
            
            createWithPromiseResolver(aliasName: aliasName,
                                      wrappedWallet: wrappedWallet,
                                      privateKeyEthereum: privateKeyEthereum,
                                      type: type,
                                      seal: seal,
                                      hasBeenBackedUp: hasBeenBackedUp)
        }
    }
    
    static func create(aliasName: String,
                       type: WalletType,
                       mnemonicsEthereum: String,
                       hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        try await withSafeCheckedThrowingContinuation({ completion in
            create(aliasName: aliasName,
                   type: type,
                   mnemonicsEthereum: mnemonicsEthereum)
            .done { wallet in
                completion(.success(wallet))
            }
            .catch { error in
                completion(.failure(error))
            }
        })
    }
    
    static func create(aliasName: String,
                       type: WalletType,
                       privateKeyEthereum: String,
                       hasBeenBackedUp: Bool = false) -> Promise<UDWalletWithPrivateSeed> {
        return Promise { seal in
            let wrappedWallet: UDWalletEthereumWithPrivateSeed
            do {
                wrappedWallet = try UDWalletEthereum.createVerified(privateKey: privateKeyEthereum)
            } catch {
                Debugger.printFailure("Failed to init UDWalletEthereum with priv key", critical: false)
                seal.reject(error)
                return
            }
            
            createWithPromiseResolver(aliasName: aliasName,
                                      wrappedWallet: wrappedWallet,
                                      privateKeyEthereum: privateKeyEthereum,
                                      type: type,
                                      seal: seal,
                                      hasBeenBackedUp: hasBeenBackedUp)
        }
    }
    
    static func create(aliasName: String,
                       type: WalletType,
                       privateKeyEthereum: String,
                       hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        try await withSafeCheckedThrowingContinuation({ completion in
            create(aliasName: aliasName,
                   type: type,
                   privateKeyEthereum: privateKeyEthereum)
            .done { wallet in
                completion(.success(wallet))
            }
            .catch { error in
                completion(.failure(error))
            }
        })
    }
    
    static func createWithoutZil(aliasName: String,
                        type: WalletType,
                        mnemonicsEthereum: String,
                        hasBeenBackedUp: Bool = false) -> Promise<UDWalletWithPrivateSeed> {
        return Promise { seal in
            let wrappedWallet: UDWalletEthereumWithPrivateSeed
            do {
                wrappedWallet = try UDWalletEthereum.createVerified(mnemonics: mnemonicsEthereum)
            } catch {
                Debugger.printFailure("Failed to init UDWalletEthereum with mnemonics", critical: false)
                seal.reject(error)
                return
            }
            
            let udWallet = UDWallet.create(aliasName: aliasName,
                                              type: type,
                                              ethWallet: wrappedWallet.ethWallet,
                                              zilWallet: nil,
                                              hasBeenBackedUp: hasBeenBackedUp)
            seal.fulfill(UDWalletWithPrivateSeed(udWallet: udWallet, privateSeed: wrappedWallet.privateSeed))
        }
    }
    
    static func createWithoutZil(aliasName: String,
                       type: WalletType,
                       mnemonicsEthereum: String,
                       hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        try await withSafeCheckedThrowingContinuation({ completion in
            createWithoutZil(aliasName: aliasName,
                   type: type,
                   mnemonicsEthereum: mnemonicsEthereum)
            .done { wallet in
                completion(.success(wallet))
            }
            .catch { error in
                completion(.failure(error))
            }
        })
    }
    
    static func createWithoutZil(aliasName: String,
                       type: WalletType,
                       privateKeyEthereum: String,
                       hasBeenBackedUp: Bool = false) -> Promise<UDWalletWithPrivateSeed> {
        return Promise { seal in
            let wrappedWallet: UDWalletEthereumWithPrivateSeed
            do {
                wrappedWallet = try UDWalletEthereum.createVerified(privateKey: privateKeyEthereum)
            } catch {
                Debugger.printFailure("Failed to init UDWalletEthereum with priv key", critical: false)
                seal.reject(error)
                return
            }
            
            let udWallet = UDWallet.create(aliasName: aliasName,
                                              type: type,
                                              ethWallet: wrappedWallet.ethWallet,
                                              zilWallet: nil,
                                              hasBeenBackedUp: hasBeenBackedUp)
            seal.fulfill(UDWalletWithPrivateSeed(udWallet: udWallet, privateSeed: wrappedWallet.privateSeed))
        }
    }
    
    static func createWithoutZil(aliasName: String,
                       type: WalletType,
                       privateKeyEthereum: String,
                       hasBeenBackedUp: Bool = false) async throws -> UDWalletWithPrivateSeed {
        try await withSafeCheckedThrowingContinuation({ completion in
            createWithoutZil(aliasName: aliasName,
                   type: type,
                   privateKeyEthereum: privateKeyEthereum)
            .done { wallet in
                completion(.success(wallet))
            }
            .catch { error in
                completion(.failure(error))
            }
        })
    }
    
    static private func createWithPromiseResolver(aliasName: String,
                                                  wrappedWallet: UDWalletEthereumWithPrivateSeed,
                                                  privateKeyEthereum: String,
                                                  type: WalletType,
                                                  seal: Resolver<UDWalletWithPrivateSeed>,
                                                  hasBeenBackedUp: Bool = false) {
        UDWalletZil.create(privateKey: privateKeyEthereum) { zil in
            guard let zilWallet = zil else {
                Debugger.printFailure("Failed to init UDWalletZil with priv key", critical: true)
                seal.reject(WalletError.zilWalletFailedInit)
                return
            }
            let udWallet = UDWallet.create(aliasName: aliasName,
                                              type: type,
                                              ethWallet: wrappedWallet.ethWallet,
                                              zilWallet: zilWallet,
                                              hasBeenBackedUp: hasBeenBackedUp)
            seal.fulfill(UDWalletWithPrivateSeed(udWallet: udWallet, privateSeed: wrappedWallet.privateSeed))
        }
    }
}
