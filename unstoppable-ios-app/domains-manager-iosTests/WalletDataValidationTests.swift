//
//  WalletDataValidationTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import XCTest
@testable import domains_manager_ios

final class WalletDataValidationTests: XCTestCase, WalletDataValidator {

    private let walletAddress = "0x397ab335485c15be06deb7a64fd87ec93da836ee3ab189441f71d51e93bf7ce0"

}

// MARK: - Wallet name validation
extension WalletDataValidationTests {
    func testWalletNameEmpty() {
        let wallet = walletInfoFor(wallet: UDWallet.createUnverified(address: walletAddress)!)
        let walletName = ""
        ensureNameResult(isNameValid(walletName, for: wallet), is: .empty)
    }
   
    func testWalletNameWithSpacesOnly() {
        let wallet = walletInfoFor(wallet: UDWallet.createUnverified(address: walletAddress)!)
        let walletName = "     \n   "
        ensureNameResult(isNameValid(walletName, for: wallet), is: .empty)
    }
    
    func testWalletNameBig() {
        let wallet = walletInfoFor(wallet: UDWallet.createUnverified(address: walletAddress)!)
        let walletName = "1234567890123456789012345"
        ensureNameResult(isNameValid(walletName, for: wallet), is: .tooLong)
    }
    
    func testWalletNameNotUnique() {
        let walletName = "Wallet"
        
        if UDWalletsStorage.instance.getWallet(byName: walletName) == nil {
            var walletWithSameName = UDWallet.createUnverified(address: walletAddress)!
            walletWithSameName.aliasName = walletName
            UDWalletsStorage.instance.add(newWallet: walletWithSameName)
        }
        
        let wallet = walletInfoFor(wallet: UDWallet.createUnverified(address: walletAddress.dropLast().appending("7"))!)
        ensureNameResult(isNameValid(walletName, for: wallet), is: .notUnique(walletName: wallet.walletSourceName))
    }
    
    func testWalletNameCorrectUnique() {
        let wallet = walletInfoFor(wallet: UDWallet.createUnverified(address: walletAddress)!)
        let walletName = "Wallet New233&*%@ +"
        switch isNameValid(walletName, for: wallet) {
        case .success:
            return
        case .failure:
            assertionFailure("This is valid wallet name")
        }
    }
}

// MARK: - Backup password validation
extension WalletDataValidationTests {
    func testBackupPasswordEmpty() {
        let password = ""
        ensureBackupPasswordResult(isBackupPasswordValid(password), is: .empty)
    }
   
    func testBackupPasswordSmall() {
        let password = "1234567"
        ensureBackupPasswordResult(isBackupPasswordValid(password), is: .tooSmall)
    }
 
    func testBackupPasswordHasNoDigits() {
        let passwords: [String] = ["qq qq qq qq", "!@#$ %^&*"]

        passwords.forEach { password in
            ensureBackupPasswordResult(isBackupPasswordValid(password), is: .noDigits)
        }
    }
 
    func testBackupPasswordHasNoLetters() {
        let password = "12345678"
        ensureBackupPasswordResult(isBackupPasswordValid(password), is: .noLetters)
    }
    
    func testValidBackupPasswords() {
        let passwords: [String] = ["      7     ", "qqqqqqq7", "qwertyui6", "12345678 ", "12345678a", "12345678 &"]
        
        passwords.forEach { password in
            switch isBackupPasswordValid(password) {
            case .success:
                return
            case .failure:
                assertionFailure("This is valid wallet password: \(password)")
            }
        }
    }
}

// MARK: - Private methods
private extension WalletDataValidationTests {
    func ensureNameResult(_ result: Result<Void, WalletNameValidationError>, is error: WalletNameValidationError) {
        switch result {
        case .success:
            assertionFailure("Result should be failure")
        case .failure(let resultError):
            XCTAssertEqual(resultError, error)
        }
    }
    
    func ensureBackupPasswordResult(_ result: Result<Void, WalletBackupPasswordValidationError>, is error: WalletBackupPasswordValidationError) {
        switch result {
        case .success:
            assertionFailure("Result should be failure")
        case .failure(let resultError):
            XCTAssertEqual(resultError, error)
        }
    }
    
    func walletInfoFor(wallet: UDWallet) -> WalletDisplayInfo {
        WalletDisplayInfo(wallet: wallet, domainsCount: 0, udDomainsCount: 0)!
    }
}
