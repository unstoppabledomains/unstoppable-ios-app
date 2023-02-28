//
//  BaseTestClass.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 10.11.2022.
//

import XCTest
@testable import domains_manager_ios

// WCV1
import WalletConnectSwift

class BaseTestClass: XCTestCase {
   
    func waitFor(interval: TimeInterval = 0.2) async throws {
        let duration = UInt64(interval * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
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
    
    func createWCV1Session() -> WalletConnectSwift.Session {
        let genericURL = URL(string: "https://g.com")!
        
        return .init(url: .init(topic: "topic", bridgeURL: genericURL, key: "key"),
                     dAppInfo: .init(peerId: "peerId",
                                     peerMeta: .init(name: "Name",
                                                     description: nil,
                                                     icons: [],
                                                     url: genericURL)),
                     walletInfo: nil)
    }
    
    func createV1UnifiedConnectAppInfo() -> UnifiedConnectAppInfo {
        let newApp = WCConnectedAppsStorage.ConnectedApp(walletAddress: walletAddress,
                                            domain: createMockDomainItem(),
                                            session: createWCV1Session(),
                                            appIconUrls: [],
                                            connectionStartDate: Date())
        return UnifiedConnectAppInfo(from: newApp)
    }

}

