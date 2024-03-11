//
//  TestableUDWalletsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableUDWalletsService: UDWalletsServiceProtocol {
    func getUserWallets() -> [UDWallet] {
        []
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
        nil
    }
    
    func setReverseResolution(to domain: DomainItem, paymentConfirmationDelegate: any PaymentConfirmationDelegate) async throws {
        
    }
    
    func migrateToUdWallets(from legacyWallets: [LegacyUnitaryWallet]) async throws {
        
    }
    
    func addListener(_ listener: any UDWalletsServiceListener) {
        
    }
    
    func removeListener(_ listener: any UDWalletsServiceListener) {
        
    }
}
