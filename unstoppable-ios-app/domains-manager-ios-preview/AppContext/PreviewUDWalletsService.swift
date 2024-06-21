//
//  PreviewUDWalletsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class UDWalletsService: UDWalletsServiceProtocol {
  
    var walletsNumberLimit: Int { 20 }
    var canAddNewWallet: Bool { true }
    
    func getUserWallets() -> [UDWallet] {
        []
    }
    
    func find(by address: HexAddress) -> UDWallet? {
        nil
    }
    
    func createNewUDWallet() async throws -> UDWallet {
        UDWallet()
    }
    
    func createWalletFor(privateKey: String) async -> UDWalletWithPrivateSeed? {
        nil
    }
    
    func isValid(privateKey: String) async -> Bool {
        true
    }
    
    func importWalletWith(privateKey: String) async throws -> UDWallet {
        UDWallet()
    }
    
    func createWalletFor(mnemonics: String) async -> UDWalletWithPrivateSeed? {
        nil
    }
    
    func isValid(mnemonics: String) async -> Bool {
        true
    }
    
    func importWalletWith(mnemonics: String) async throws -> UDWallet {
        UDWallet()
    }
    
    func addExternalWalletWith(address: String, walletRecord: WCWalletsProvider.WalletRecord) throws -> UDWallet {
        UDWallet()
    }
    
    func createMPCWallet(ethAddress: HexAddress,
                         mpcMetadata: MPCWalletMetadata) throws -> UDWallet {
        UDWallet.createMPC(address: ethAddress, mpcMetadata: mpcMetadata)
    }
    
    
    func remove(wallet: UDWallet) {
        
    }
    
    func removeAllWallets() {
        
    }
    
    func rename(wallet: UDWallet, with name: String) -> UDWallet? {
        wallet
    }
    
    func fetchCloudWalletClusters() -> [WalletCluster] {
        []
    }
    
    func backUpWallet(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet {
        wallet
    }
    
    func backUpWalletToCurrentCluster(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet {
        wallet
    }
    
    func restoreAndInjectWallets(using password: String) async throws -> [UDWallet] {
        []
    }
    
    func eraseAllBackupClusters() {
        
    }
    
    func reverseResolutionDomainName(for wallet: UDWallet) async throws -> DomainName? {
        nil
    }
    
    func reverseResolutionDomainName(for walletAddress: HexAddress) async throws -> DomainName? {
        nil
    }
    
    func setReverseResolution(to domain: DomainItem, paymentConfirmationHandler: PaymentConfirmationHandler) async throws {
        
    }
    
    func migrateToUdWallets(from legacyWallets: [LegacyUnitaryWallet]) async throws {
        
    }
    
    func addListener(_ listener: UDWalletsServiceListener) {
        
    }
    
    func removeListener(_ listener: UDWalletsServiceListener) {
        
    }
    
    
    
}

extension UDWalletsService {
    struct WalletCluster {
        init(backedUpWallets: [BackedUpWallet]) {
            assert(!backedUpWallets.isEmpty)
            self.date = backedUpWallets.sorted(by: { $0.dateTime > $1.dateTime} ).first!.dateTime
            self.passwordHash = backedUpWallets.first!.passwordHash
            self.wallets = backedUpWallets
            self.isCurrent = true
        }
        
        var date: Date
        let passwordHash: String
        let wallets: [BackedUpWallet]
        let isCurrent: Bool
    }
}
