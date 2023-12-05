//
//  Domain.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 06.10.2020.
//

import Foundation
import UIKit

struct DomainItem: DomainEntity, Codable, Equatable {
    
    enum Status: String, Codable {
        case unclaimed
        case claiming
        case confirmed
    }
    
    var name: String
    var ownerWallet: String? = nil
    var resolver: String? = nil
    var blockchain: BlockchainType? = nil
    var pfpURL: String?
    var imageType: DomainProfileImageType?
    var transactionHashes: [HexAddress] = []
    var claimingTxId: UInt64?
    var status: Status = .confirmed
    
    func inject(owner: HexAddress) -> DomainItem {
        var domainCopy = self
        domainCopy.ownerWallet = owner
        return domainCopy
    }
    
    func merge(with newDomain: DomainItem) -> DomainItem {
        var origin = self
        origin.name = newDomain.name
        origin.ownerWallet = newDomain.ownerWallet
        if claimingTxId == nil {
            origin.claimingTxId = newDomain.claimingTxId
        }
        origin.status = newDomain.status
        origin.blockchain = newDomain.blockchain
        return origin
    }
}

extension DomainItem {
    init(jsonResponse: NetworkService.DomainResponse) {
        self.name = jsonResponse.name
        self.ownerWallet = jsonResponse.ownerAddress
        self.blockchain = try? BlockchainType.getType(abbreviation: jsonResponse.blockchain)
        self.resolver = jsonResponse.resolver
    }
}

extension DomainItem: Hashable { }

extension DomainItem: CustomStringConvertible {
    var description: String {
        "Domain: \(name), claimId: \(String(describing: claimingTxId))"
    }
}

extension DomainItem: APIRepresentable {
    var apiRepresentation: String {
        "\(name)"
    }
}

// Decision methods based on DomainItem values

extension DomainItem {
    /// This method checks whether or not TxCost that came from backend is valid.
    /// Domains of ZNS should always have TxCost == nil
    /// Domains from UNS should have TxCost as value only when the backend is real
    /// - Parameters:
    ///   - service: NamingService
    ///   - txCost: Optional TxCost that needs to be validated
    /// - Returns: validation
    static func isValidTxCost(blockchain: BlockchainType, txCost: NetworkService.TxCost?) -> Bool {
        switch blockchain {
        case .Ethereum: return txCost != nil
        case .Zilliqa, .Matic: return txCost == nil
        }
    }
}

extension DomainItem {
    public func ethSign(message: String) async throws -> String {
        guard let ownerAddress = self.ownerWallet,
              let ownerWallet = appContext.udWalletsService.find(by: ownerAddress) else {
            throw NetworkLayerError.failedToFindOwnerWallet
        }
        return try await ownerWallet.getEthSignature(messageString: message)
    }
    
    public func personalSign(message: String) async throws -> String {
        guard let ownerAddress = self.ownerWallet,
              let ownerWallet = appContext.udWalletsService.find(by: ownerAddress) else {
            throw NetworkLayerError.failedToFindOwnerWallet
        }
        return try await ownerWallet.getPersonalSignature(messageString: message)
    }
    
    public func typedDataSign(message: String) async throws -> String {
        guard let ownerAddress = self.ownerWallet,
              let ownerWallet = appContext.udWalletsService.find(by: ownerAddress) else {
            throw NetworkLayerError.failedToFindOwnerWallet
        }
        return try await ownerWallet.getSignTypedData(dataString: message)
    }
}

extension DomainItem {
    static func createTxPayload(blockchain: BlockchainType,
                                paymentInfo: NetworkService.ActionsPaymentInfo,
                                txs: [NetworkService.ActionsTxInfo]) throws -> NetworkService.TxPayload {
        let txCost = NetworkService.TxCost(quantity: 1,
                                           stripeIntent: paymentInfo.id,
                                           stripeSecret: paymentInfo.clientSecret,
                                           gasPrice: 0, gasLimit: 0, usdToEth: 0, fee: 0,
                                           price: Int(paymentInfo.totalAmount))
        
        let messages = txs.compactMap { $0.messageToSign }
        guard messages.count == txs.count else { throw NetworkLayerError.noMessageError }
        return NetworkService.TxPayload(messages: messages,
                                        txCost: txCost)
    }
}

struct CryptoTxPayload {
    let resolverAddress: HexAddress?
    var txCosts: [NetworkService.TxCost] = []
}

protocol CryptoPayloadHolder {
    var cryptoPayload: CryptoTxPayload? { get set }
}

extension Array where Element == DomainItem {
    func contains(domain: DomainItem) -> Bool {
        return self.first(where: { $0.name == domain.name }) != nil
    }
    
    func sortedByName() -> [DomainItem] {
        sorted(by: { $0.name < $1.name })
    }
}

extension Array where Element == DomainItem {
    func filterZilCoOwned(by ownerAddress: HexAddress) -> Self {
        return filterCoOwned(by: ownerAddress, in: .ZNS)
    }
    
    func filterCoOwned(by ownerAddress: HexAddress, in namingService: NamingService) -> Self {
        return self.filter({$0.namingService == namingService &&  $0.ownerWallet?.normalized == ownerAddress.normalized})
    }
}

extension DomainItem {
    static func getViewingDomainFor(messagingProfile: MessagingChatUserProfileDisplayInfo) async -> DomainItem? {
        let userDomains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
        let walletDomains = userDomains.filter({ $0.ownerWallet?.normalized == messagingProfile.wallet.normalized })
        guard let viewingDomainDisplayInfo = walletDomains.first(where: { $0.isSetForRR }) ?? walletDomains.first,
              let viewingDomain = try? await appContext.dataAggregatorService.getDomainWith(name: viewingDomainDisplayInfo.name) else { return nil }
        
        return viewingDomain
    }
}

extension DomainItem {
    /// This method puts a rule whether or not the domains requires payment for a critical trnasaction.
    /// True means that the app will launch Apple Pay flow and will depend on the backend
    /// - Returns: Bool
    func doesRequirePayment() -> Bool {
        switch self.getBlockchainType() {
        case .Ethereum: return true
        case .Zilliqa, .Matic: return false
        }
    }
}
