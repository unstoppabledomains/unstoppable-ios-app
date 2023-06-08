//
//  PrivateKeyStorageTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 09.03.2022.
//

import XCTest
@testable import domains_manager_ios

class PrivateKeyStorageTests: XCTestCase {
    var keyStorage: MockedPrivateKeyStorage!
    var mockedICloud: iCloudWalletStorage!
    
    override func setUpWithError() throws {
        keyStorage = MockedPrivateKeyStorage()
        mockedICloud = iCloudWalletStorage(storage: keyStorage)
    }
    
    let password = "The most advanced password in the village"
    
    func testAddingWallets() throws {
        let backUpPassword = WalletBackUpPassword(password)!
        var wallets = mockedICloud.findWallets(password: password)
        XCTAssert(wallets.count == 0)
        
        let walletData1 = iCloudWalletStorage.WalletData(name: "Wallet1", pkOrSeed: "12345", type: "GENERATED")
        let entry1 = iCloudWalletStorage.WalletEntry(wallet: walletData1, ph: backUpPassword.value, datetime: Date().stringUTC)
        try! mockedICloud.save(wallet: BackedUpWallet(walletEntry: entry1)!)
        wallets = mockedICloud.findWallets(password: password)
        XCTAssert(wallets.count == 1)
        
        let walletData2 = iCloudWalletStorage.WalletData(name: "Wallet2", pkOrSeed: "1234567890", type: "IMPORTED_BY_PRIVATE_KEY")
        let entry2 = iCloudWalletStorage.WalletEntry(wallet: walletData2, ph: backUpPassword.value, datetime: Date().stringUTC)
        try! mockedICloud.save(wallet: BackedUpWallet(walletEntry: entry2)!)
        
        wallets = mockedICloud.findWallets(password: password)
        XCTAssert(wallets.count == 2)
        
        XCTAssert(wallets[0].encryptedPrivateSeed.description == "12345")
        XCTAssert(wallets[1].encryptedPrivateSeed.description == "1234567890")
    }
    
    func testEncryptingDecryptingAES() {
        let messagesAndPasswords = [
            ("trumpet merge fix divorce scheme elevator very bean endless they resemble supply", "11111111"),
            ("There was a thing", "qwertyasdfgh12"),
                                    ("73838ab47393", "1234"),
                                    ("Once upon a time 7483857383\nwhatever it may be", "YEYEBE")]
        
        do {
            try messagesAndPasswords.forEach {
                let encrypted = try Encrypting.encrypt(message: $0.0, with: $0.1)
                
                let decrypted = try Encrypting.decrypt(encryptedMessage: encrypted.hexToBytes(), password: $0.1)
                
                XCTAssert($0.0 == decrypted, "Decrypted must be equal to the origin")
            }
        } catch {
            XCTAssert(false, "Error in encrypting/decrypting, error: \(error.localizedDescription)")
        }
    }
}

class MockedValet: ValetProtocol {
    var store: [String: String] = [:]
    func setString(_ privateKey: String, forKey: String) throws {
        store.updateValue(privateKey, forKey: forKey)
    }

    func string(forKey pubKeyHex: String) throws -> String {
        guard let response = store[pubKeyHex] else {
            throw ValetError.failedToRead
        }
        return response
    }

    func removeObject(forKey: String) throws {
        store.removeValue(forKey: forKey)
    }
}

class MockedPrivateKeyStorage: PrivateKeyStorage {
    init() { valet = MockedValet() }
    var valet: ValetProtocol
}
