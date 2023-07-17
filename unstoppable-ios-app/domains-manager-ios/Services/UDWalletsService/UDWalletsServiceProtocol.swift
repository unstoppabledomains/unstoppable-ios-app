//
//  UDWalletsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import Foundation

protocol UDWalletsServiceProtocol {
    // Get
    func getUserWallets() -> [UDWallet]
    func find(by address: HexAddress) -> UDWallet?
    
    // Add
    func createNewUDWallet() async throws -> UDWallet
    
    func createWalletFor(privateKey: String) async -> UDWalletWithPrivateSeed?
    func isValid(privateKey: String) async -> Bool
    func importWalletWith(privateKey: String) async throws -> UDWallet
    
    func createWalletFor(mnemonics: String) async -> UDWalletWithPrivateSeed?
    func isValid(mnemonics: String) async -> Bool
    func importWalletWith(mnemonics: String) async throws -> UDWallet
    
    func addExternalWalletWith(address: String, walletRecord: WCWalletsProvider.WalletRecord) throws -> UDWallet
    func remove(wallet: UDWallet)
    func removeAllWallets()
    
    // Edit
    func rename(wallet: UDWallet, with name: String) -> UDWallet?
    
    // Backup
    func fetchCloudWalletClusters() -> [UDWalletsService.WalletCluster]
    func backUpWallet(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet
    func backUpWalletToCurrentCluster(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet
    func restoreAndInjectWallets(using password: String) async throws -> [UDWallet]
    func eraseAllBackupClusters()
    
    // Balance
    func getBalanceFor(walletAddress: HexAddress, blockchainType: BlockchainType, forceRefresh: Bool) async throws -> WalletBalance
    
    // Reverse Resolution
    func reverseResolutionDomainName(for wallet: UDWallet) async throws -> DomainName?
    func reverseResolutionDomainName(for walletAddress: HexAddress) async throws -> DomainName?
    func setReverseResolution(to domain: DomainItem,
                                   paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws
    
    // Migration
    func migrateToUdWallets(from legacyWallets: [LegacyUnitaryWallet]) async throws
    
    // Listeners
    func addListener(_ listener: UDWalletsServiceListener)
    func removeListener(_ listener: UDWalletsServiceListener)
}

protocol UDWalletsServiceListener: AnyObject {
    func walletsDataUpdated(notification: UDWalletsServiceNotification)
}

enum UDWalletsServiceNotification {
    case walletsUpdated(_ wallets: [UDWallet])
    case reverseResolutionDomainChanged(domainName: String, txIds: [UInt64])
    case walletRemoved(_ wallet: UDWallet)
}

final class UDWalletsListenerHolder: Equatable {
    
    weak var listener: UDWalletsServiceListener?
    
    init(listener: UDWalletsServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: UDWalletsListenerHolder, rhs: UDWalletsListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

enum WalletImportingError: String, RawValueLocalizable, Error {
    case noWalletsToImport = "NO_WALLETS_TO_IMPORT"
}
