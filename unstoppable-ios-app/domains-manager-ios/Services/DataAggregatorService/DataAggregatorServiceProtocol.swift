//
//  DataAggregatorServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.05.2022.
//

import Foundation

protocol DataAggregatorServiceProtocol {
    func aggregateData() async
    func getWalletsWithInfo() async -> [WalletWithInfo]
    func getWalletsWithInfoAndBalance(for blockchainType: BlockchainType) async throws -> [WalletWithInfoAndBalance]
    func getWalletDisplayInfo(for wallet: UDWallet) async -> WalletDisplayInfo?
    func getDomains() async -> [DomainItem]
    func setPrimaryDomainWith(name: String) async
    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainItem?
    func isReverseResolutionSetupInProgress(for domainName: DomainName) async -> Bool
    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool
    func isReverseResolutionChangeAllowed(for domain: DomainItem) async -> Bool
    func isReverseResolutionSet(for domainName: DomainName) async -> Bool
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     newPrimaryDomain: String?,
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [MintingDomain]
    
    func addListener(_ listener: DataAggregatorServiceListener)
    func removeListener(_ listener: DataAggregatorServiceListener)
    func getReverseResolutionDomain(for walletAddress: HexAddress) async -> String?
}

typealias DataAggregationResult = Result<DataAggregationServiceResult, Error>

protocol DataAggregatorServiceListener: AnyObject {
    func dataAggregatedWith(result: DataAggregationResult)
}

final class DataAggregatorListenerHolder: Equatable {
    
    weak var listener: DataAggregatorServiceListener?
    
    init(listener: DataAggregatorServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: DataAggregatorListenerHolder, rhs: DataAggregatorListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

enum DataAggregationServiceResult {
    case domainsUpdated(_ domains: [DomainItem])
    case domainsPFPUpdated(_ allDomains: [DomainItem])
    case walletsListUpdated(_ walletsWithInfo: [WalletWithInfo])
    case primaryDomainChanged(_ name: String)
}
