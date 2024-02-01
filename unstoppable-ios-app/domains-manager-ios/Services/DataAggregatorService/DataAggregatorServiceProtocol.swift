//
//  DataAggregatorServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.05.2022.
//

import Foundation

protocol DataAggregatorServiceProtocol {
    func aggregateData(shouldRefreshPFP: Bool) async
//    func getWalletsWithInfo() async -> [WalletWithInfo]
//    func getWalletDisplayInfo(for wallet: UDWallet) async -> WalletDisplayInfo?
//    func getDomainItems() async -> [DomainItem]
//    func getDomainsDisplayInfo() async -> [DomainDisplayInfo]
//    func getDomainWith(name: String) async throws -> DomainItem
//    func getDomainsWith(names: Set<String>) async -> [DomainItem]
//    func setDomainsOrder(using domains: [DomainDisplayInfo]) async
//    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainDisplayInfo?
//    func isReverseResolutionSetupInProgress(for domainName: DomainName) async -> Bool
//    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool
//    func isReverseResolutionChangeAllowed(for domain: DomainDisplayInfo) async -> Bool
//    func isReverseResolutionSet(for domainName: DomainName) async -> Bool
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     domainsOrderInfoMap: SortDomainsOrderInfoMap,
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [MintingDomain]
    func didPurchaseDomains(_ purchasedDomains: [PendingPurchasedDomain],
                            pendingProfiles: [DomainProfilePendingChanges]) async
    
//    func addListener(_ listener: DataAggregatorServiceListener)
//    func removeListener(_ listener: DataAggregatorServiceListener)
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

enum DataAggregationServiceResult: Sendable {
    case domainsUpdated(_ domains: [DomainDisplayInfo])
    case domainsPFPUpdated(_ allDomains: [DomainDisplayInfo])
    case walletsListUpdated(_ walletsWithInfo: [WalletWithInfo])
    case primaryDomainChanged(_ name: String)
}
