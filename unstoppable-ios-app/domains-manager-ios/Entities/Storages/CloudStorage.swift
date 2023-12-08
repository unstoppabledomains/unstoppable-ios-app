//
//  CloudStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.01.2023.
//

import Foundation

protocol CloudStorageProtocol {
    func getWallets() -> [BackedUpWallet]
}

extension CloudStorageProtocol {
    var storageFilekey: String { "ud_backup" }
}

struct iCloudWalletStorage: CloudStorageProtocol {
    
    enum Error: String, Swift.Error {
        case alreadyBackedup = "This wallet is already backed up"
    }
    
    static let workerQueue = DispatchQueue(label: "ud-iCloudWalletStorage-WorkerQueue")
  
    static func isICloudAvailable() -> Bool {
        #if DEBUG
        if TestsEnvironment.isTestModeOn {
            return TestsEnvironment.isICloudAvailableToUse
        }
        #endif
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    struct WalletData: Codable {
        let name: String
        let pkOrSeed: String
        let type: String
    }
    
    struct WalletEntry: Codable {
        let wallet: WalletData
        let ph: String
        let datetime: String
        
        init(wallet: WalletData, ph: String, datetime: String) {
            self.wallet = wallet
            self.ph = ph
            self.datetime = datetime
        }

        init?(wallet: BackedUpWallet) {
            guard let typeString = wallet.type.getICloudLabel() else {
                Debugger.printFailure("Failed to parse typeString from: \(wallet.type)", critical: true)
                return nil }
            let walletData = WalletData(name: wallet.name,
                                        pkOrSeed: wallet.encryptedPrivateSeed.description,
                                        type: typeString)
            self.wallet = walletData
            self.ph =  wallet.passwordHash
            self.datetime =  Date().stringUTC
        }
    }
    
    struct File: Codable {
        static let currentSchemaVersion = 1

        let schemaVersion: Int
        private var data: [WalletEntry]
        
        static func createEmpty() -> File {
            File(schemaVersion: Self.currentSchemaVersion, data: [])
        }
        
        func getWalletEntries() -> [WalletEntry] {
            data
        }
        
        mutating func append(backedupWallet: BackedUpWallet) throws {
            guard let entry = WalletEntry(wallet: backedupWallet) else { return }
            data.append(entry)
        }
    }

    let storage: PrivateKeyStorage
    
    static func create() -> iCloudWalletStorage {
        let iCloudStorage = iCloudPrivateKeyStorage()
        return iCloudWalletStorage(storage: iCloudStorage)
    }
    
    static func saveToiCloud(wallets: [UDWallet], password: String) -> Bool {
        do {
            try Self.workerQueue.sync {
                let storage = iCloudWalletStorage.create()
                var file = storage.getStorageContents()
                
                try wallets
                    .compactMap({BackedUpWallet(udWallet: $0, password: password)})
                    .forEach {
                        try file.append(backedupWallet: $0)
                    }
                
                storage.saveStorageContents(file: file)
            }
        } catch {
            Debugger.printFailure("Failed append wallets to the JSON file: \(wallets)", critical: true)
            return false
        }
        return true
    }
    
    func save(wallet: BackedUpWallet) throws {
        try Self.workerQueue.sync {
            var file = getStorageContents()
            try file.append(backedupWallet: wallet)
            saveStorageContents(file: file)
        }
    }

    func getWallets() -> [BackedUpWallet] {
        return getStorageContents()
            .getWalletEntries()
            .compactMap({BackedUpWallet(walletEntry: $0)})
    }
    
    func clear() {
        Self.workerQueue.sync {
            let file = File.createEmpty()
            saveStorageContents(file: file)
        }
    }
    
    private func getStorageContents() -> File {
        guard let file = storage.retrieveValue(for: storageFilekey, isCritical: false) else {
            return File.createEmpty()
        }
        
        guard let data = file.data(using: .utf8),
              let fileContents = try? JSONDecoder().decode(File.self, from: data) else {
            Debugger.printWarning("Found no backup file in iCloud")
            return File.createEmpty() }
        
        guard fileContents.schemaVersion == File.currentSchemaVersion else {
            Debugger.printFailure("Current schema version is older than \(fileContents.schemaVersion)", critical: true)
            return File.createEmpty()
        }
        
        return fileContents
    }
    
    private func saveStorageContents(file: File) {
        guard let dataString = file.jsonString() else {
            Debugger.printWarning("File failed to encode")
            return
        }
        storage.store(value: dataString, for: storageFilekey)
        return
    }
    
    func numberOfSavedWallets() -> Int {
        getWallets().count
    }
    
    func findWallets(password: String) -> [BackedUpWallet] {
        let backUpPassword = WalletBackUpPassword(password)
        return getWallets().filter({ $0.passwordHash == backUpPassword?.value })
    }
}
