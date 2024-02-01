//
//  BaseTestClass.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 10.11.2022.
//

import XCTest
@testable import domains_manager_ios

class BaseTestClass: XCTestCase {
   
    func waitFor(interval: TimeInterval = 0.2) async throws {
        let duration = UInt64(interval * 1_000_000_000)
        await Task.sleep(nanoseconds: duration)
    }
    
    private var walletAddress: HexAddress { "0x1944dF1425C2237Ec501206ba416B82f47f9901d" }

    func generateNewWalletAddress() -> HexAddress {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let numOfChangedChars = 5
        var address = self.walletAddress
        
        for _ in 0..<numOfChangedChars {
            address.removeLast()
        }
        
        for _ in 0..<numOfChangedChars {
            address.append(letters.randomElement()!)
        }
        
        return address
    }
    
    func createUnverifiedUDWallet() -> UDWallet {
        let address = generateNewWalletAddress()
        var wallet = UDWallet.createUnverified(address: address)!
        wallet.aliasName = wallet.address
        
        return wallet
    }
    
    func createLocallyGeneratedBackedUpUDWallet() -> UDWallet {
        var wallet = createUnverifiedUDWallet()
        wallet.aliasName = "Wallet"
        wallet.type = .generatedLocally
        wallet.hasBeenBackedUp = true
        
        return wallet
    }
    
    func createMockDomainItem() -> DomainItem {
        DomainItem(name: "olegkuhkjdfsjhfdkhflakjhdfi748723642in.coin", blockchain: .Ethereum)
    }
}

