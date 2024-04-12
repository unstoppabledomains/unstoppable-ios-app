//
//  BackedUpWallet.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.01.2023.
//

import Foundation

struct BackedUpWallet {
    let name: String
    let encryptedPrivateSeed: Seed
    let dateTime: Date
    let type: WalletType
    let passwordHash: String
    
    init? (udWallet: UDWallet, password: String) {
        guard let backUpPassword = WalletBackUpPassword(password) else {
            return nil
        }
        self.name = udWallet.aliasName
        self.dateTime = Date()
        self.type = udWallet.type
        self.passwordHash = backUpPassword.value
        
        if udWallet.type == .privateKeyEntered {
            guard let pk = udWallet.getPrivateKey(),
                  let pkEncrypted = try? Encrypting.encrypt(message: pk, with: password) else { return nil }
            self.encryptedPrivateSeed = Seed.encryptedPrivateKey(pkEncrypted)
        } else {
            guard let mnem = udWallet.getMnemonics(),
                  let mnemEncrypted = try? Encrypting.encrypt(message: mnem, with: password) else { return nil }
            self.encryptedPrivateSeed = Seed.encryptedSeedPhrase(mnemEncrypted)
        }
    }
    
    enum Error: Swift.Error {
        case failedParseFromUDWallet
    }
}

extension BackedUpWallet {
    init? (walletEntry: iCloudWalletStorage.WalletEntry) {
        self.name = walletEntry.wallet.name
        guard let type = WalletType(iCloudLabel: walletEntry.wallet.type) else {
            Debugger.printFailure("Failed to parse type from: \(walletEntry.wallet.type)", critical: true)
            return nil }
        self.type = type

        self.encryptedPrivateSeed = type == .privateKeyEntered ?
                    Seed.encryptedPrivateKey(walletEntry.wallet.pkOrSeed)
                :   Seed.encryptedSeedPhrase(walletEntry.wallet.pkOrSeed)
        
        self.dateTime = Date(stringUTC: walletEntry.datetime)
        self.passwordHash = walletEntry.ph
    }
}

extension Array where Element == BackedUpWallet {
    func containUDVault() -> Bool {
        self.first(where: { $0.type == .generatedLocally || $0.type == .defaultGeneratedLocally }) != nil
    }
}
