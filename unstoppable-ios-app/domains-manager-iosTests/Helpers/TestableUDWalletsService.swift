//
//  TestableUDWalletsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableUDWalletsService: UDWalletsServiceProtocol {
    
    var listeners: [UDWalletsServiceListener] = []
    var rrDomainNamePerWallet: [HexAddress : DomainName] = [:]
    
    var wallets: [UDWallet] = [UDWallet.createUnverified(aliasName: "0xc4a748796805dfa42cafe0901ec182936584cc6e",
                                                         address: "0xc4a748796805dfa42cafe0901ec182936584cc6e")!,
                               UDWallet.createUnverified(aliasName: "Custom name",
                                                         address: "0x537e2EB956AEC859C99B3e5e28D8E45200C4Fa52")!]
    
    func getUserWallets() -> [UDWallet] {
        wallets
    }
    
    func find(by address: HexAddress) -> UDWallet? {
        nil
    }
    
    var walletsNumberLimit: Int { 0 }
    
    var canAddNewWallet: Bool { true }
    
    func createNewUDWallet() async throws -> UDWallet {
        throw TestableGenericError.generic
    }
    
    func createWalletFor(privateKey: String) async -> UDWalletWithPrivateSeed? {
        nil
    }
    
    func isValid(privateKey: String) async -> Bool {
        true
    }
    
    func importWalletWith(privateKey: String) async throws -> UDWallet {
        throw TestableGenericError.generic

    }
    
    func createWalletFor(mnemonics: String) async -> UDWalletWithPrivateSeed? {
        nil
    }
    
    func isValid(mnemonics: String) async -> Bool {
        true
    }
    
    func importWalletWith(mnemonics: String) async throws -> UDWallet {
        throw TestableGenericError.generic
    }
    
    func addExternalWalletWith(address: String, walletRecord: WCWalletsProvider.WalletRecord) throws -> UDWallet {
        throw TestableGenericError.generic
    }
    
    func remove(wallet: UDWallet) {
        
    }
    
    func removeAllWallets() {
        
    }
    
    func rename(wallet: UDWallet, with name: String) -> UDWallet? {
        wallet
    }
    
    func fetchCloudWalletClusters() -> [UDWalletsService.WalletCluster] {
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
        rrDomainNamePerWallet[walletAddress]
    }
    
    func setReverseResolution(to domain: DomainItem, paymentConfirmationDelegate: any PaymentConfirmationDelegate) async throws {
        
    }
    
    func migrateToUdWallets(from legacyWallets: [LegacyUnitaryWallet]) async throws {
        
    }
    
    func addListener(_ listener: any UDWalletsServiceListener) {
        listeners.append(listener)
    }
    
    func removeListener(_ listener: any UDWalletsServiceListener) {
        
    }
}

// MARK: - Open methods
extension TestableUDWalletsService {
    func notifyWith(_ notification: UDWalletsServiceNotification) {
        listeners.forEach { listener in
            listener.walletsDataUpdated(notification: notification)
        }
    }
}
