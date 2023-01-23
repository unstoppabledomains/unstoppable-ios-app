//
//  UDWalletZil.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 18.03.2021.
//

import Foundation
import Zesame

class UDWalletZil: AddressContainer, Codable  {
    var address: String
    var hasPrivateKey: Bool?
    
    var bech32addressMainnet: String
    var bech32addressTestnet: String
    static let defaultPassword = "1234567890"
    static var network: Network {
        return .mainnet
    }

    private init(address: String, bech32addressMainnet: String?, bech32addressTestnet: String?) {
        self.address = address
        if let bech32main = bech32addressMainnet,
           let bech32test = bech32addressTestnet {
            self.bech32addressMainnet = bech32main
            self.bech32addressTestnet = bech32test
        } else {
            self.bech32addressMainnet = "bech32 address failed"
            self.bech32addressTestnet = "bech32 address failed"
            Debugger.printFailure("Bech32 failed to create for address: \(address)", critical: true)
        }
        self.hasPrivateKey = false
    }
        
    static func createUnverified(address: String, humanAddress: String) -> UDWalletZil {
        let wallet = UDWalletZil(address: address, bech32addressMainnet: humanAddress, bech32addressTestnet: humanAddress)
        wallet.hasPrivateKey = false
        return wallet
    }
    
    private static func create(restoration: Zesame.KeyRestoration, completion: @escaping (UDWalletZil?, String?) -> Void) {
        switch restoration {
        case .keystore(let keystore, let password):
            let wallet = Wallet(keystore: keystore)
            wallet.keystore.decryptPrivateKeyWith(password: password) { prKeyResult in
                switch prKeyResult {
                case .success(let key):
                    let bech32StringMain = try? Bech32Address(ethStyleAddress: wallet.address, network: .mainnet).asString
                    let bech32StringTest = try? Bech32Address(ethStyleAddress: wallet.address, network: .testnet).asString
                    let udZilWallet = UDWalletZil(address: wallet.address.asHex,
                                                  bech32addressMainnet: bech32StringMain,
                                                  bech32addressTestnet: bech32StringTest)
                    udZilWallet.hasPrivateKey = true
                    completion(udZilWallet, key.asHex())
                case .failure: completion(nil, nil)
                }
            }
        case .privateKey(let privateKey, let newPassword, let kdf):
            do {
                try Keystore.from(privateKey: privateKey, encryptBy: newPassword, kdf: kdf) {
                    guard case .success(let keystore) = $0 else {
                        completion(nil, nil)
                        return
                    }
                    let wallet = Wallet(keystore: keystore)
                    let bech32StringMain = try? Bech32Address(ethStyleAddress: wallet.address, network: .mainnet).asString
                    let bech32StringTest = try? Bech32Address(ethStyleAddress: wallet.address, network: .testnet).asString
                    let udZilWallet = UDWalletZil(address: wallet.address.asHex,
                                                bech32addressMainnet: bech32StringMain,
                                                bech32addressTestnet: bech32StringTest)
                    udZilWallet.hasPrivateKey = true
                    completion(udZilWallet, privateKey.asHex())
                }
            } catch {
                completion(nil, nil)
            }
        }
    }
    
    static func create(keystoreJson: String,
                       encryptionPassword: String,
                       completion: @escaping (UDWalletZil?, String?)->Void) {
        guard let keyRestoration = try? KeyRestoration(keyStoreJSON: keystoreJson.data(using: .utf8)!, encryptedBy: encryptionPassword) else {
            completion(nil, nil)
            return
        }
        create(restoration: keyRestoration) { zil, privateKey in
            completion(zil, privateKey)
        }
    }
    
    static func create(privateKey: String, completion: @escaping (UDWalletZil?)->Void){
        let keyHex = privateKey.droppingLeading0x().uppercased()
        guard let keyRestoration = try? KeyRestoration(privateKeyHexString: keyHex, encryptBy: defaultPassword) else {
            completion(nil)
            return
        }
        create(restoration: keyRestoration) { zil, _ in
            completion(zil)
        }
    }
}

enum WalletZilError: String, Swift.Error {
    case failedToRestoreFromJson = "Failed to restore ZIL wallet from JSON"
    case failedToRestoreFromPrivateKey = "Failed to restore ZIL wallet from private key"
}
