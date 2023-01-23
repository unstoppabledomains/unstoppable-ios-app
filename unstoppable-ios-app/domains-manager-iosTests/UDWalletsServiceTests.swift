//
//  UDWalletsTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 19.07.2022.
//

import XCTest
@testable import domains_manager_ios

final class UDWalletsServiceTests: XCTestCase {

    private let walletsService = UDWalletsService()
    let testVaultAddress = "0x1dde675c23a4cc915250c3f25d064423bcdb9348"
    let testVaultSP = "claw aware invest hero pizza pact merge elder topple weekend glare thing"
    let testVaultPK = "56ad4b6a1221863fc01a34a9a72690ada102ca77cfeeaa6db09bc46383b09490"
    
    
    override func setUpWithError() throws {
        removeTestVault()
    }

    override func tearDownWithError() throws {
        removeTestVault()
    }

    func testCreateUDVault() async throws {
        let wallet = try await walletsService.createNewUDWallet()
        XCTAssertNotNil(getVaultWith(address: wallet.address))
        walletsService.remove(wallet: wallet)
    }
    
    func testImportWalletWithSeedPhrase() async throws {
        guard getTestVault() == nil else {
            fatalError("Wallet already exist")
        }
        
        let wallet = try await walletsService.importWalletWith(mnemonics: testVaultSP)
        XCTAssertEqual(wallet.address, testVaultAddress)
        XCTAssertNotNil(getTestVault())
    }

    func testImportWalletWithPrivateKey() async throws {
        guard getTestVault() == nil else {
            fatalError("Wallet already exist")
        }
        
        let wallet = try await walletsService.importWalletWith(privateKey: testVaultPK)
        XCTAssertEqual(wallet.address, testVaultAddress)
        XCTAssertNotNil(getTestVault())
    }
    
    func testWalletSeedPhraseValidation() async throws {
        let validValue = await walletsService.isValid(mnemonics: testVaultSP)
        XCTAssertTrue(validValue)
        
        let _ = try await walletsService.importWalletWith(mnemonics: testVaultSP)
        let validValueIfWalletAdded = await walletsService.isValid(mnemonics: testVaultSP)
        XCTAssertTrue(validValueIfWalletAdded)
        
        let notValidSeedPhrase = testVaultSP.dropLast()
        let notValidValue = await walletsService.isValid(mnemonics: String(notValidSeedPhrase))
        XCTAssertFalse(notValidValue)
    }
    
    func testWalletPrivateKeyValidation() async throws {
        let validValue = await walletsService.isValid(privateKey: testVaultPK)
        XCTAssertTrue(validValue)
        
        let _ = try await walletsService.importWalletWith(privateKey: testVaultPK)
        let validValueIfWalletAdded = await walletsService.isValid(privateKey: testVaultPK)
        XCTAssertTrue(validValueIfWalletAdded)
        
        let notValidPrivateKey = testVaultPK.dropLast()
        let notValidValue = await walletsService.isValid(privateKey: String(notValidPrivateKey))
        XCTAssertFalse(notValidValue)
    }
    
    func testAddSameWallet() async throws {
        let _ = try await walletsService.importWalletWith(privateKey: testVaultPK)
        
        try await XCTAssertThrowsErrorAsync(try await walletsService.importWalletWith(privateKey: testVaultPK))
        try await XCTAssertThrowsErrorAsync(try await walletsService.importWalletWith(mnemonics: testVaultSP))
    }
}

// MARK: - Private methods
private extension UDWalletsServiceTests {
    func getVaultWith(address: String) -> UDWallet? {
        walletsService.getUserWallets().first(where: { $0.address == address })
    }
    
    func getTestVault() -> UDWallet? {
        getVaultWith(address: testVaultAddress)
    }
    
    func removeTestVault() {
        if let wallet = getTestVault() {
            walletsService.remove(wallet: wallet)
        }
    }
}
