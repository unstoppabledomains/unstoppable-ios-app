//
//  Domain.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 06.10.2020.
//

import Foundation
import UIKit

struct DomainItem: DomainEntity, Codable {
    
    enum Status: String, Codable {
        case unclaimed
        case claiming
        case confirmed
    }
    
    var name: String
    var registry: String?
    var tokenId: String? = nil
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
        if tokenId == nil {
            origin.tokenId = newDomain.tokenId
        }
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
//    public func sign(message: String) async throws -> String {
//        guard let ownerAddress = self.ownerWallet,
//              let ownerWallet = appContext.udWalletsService.find(by: ownerAddress) else {
//            throw NetworkLayerError.failedToFindOwnerWallet
//        }
//        return try await ownerWallet.getCryptoSignature(messageString: message)
//    }
    
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

enum NamingService: String, Codable, CaseIterable {
    case UNS
    case ZNS = "zil"
    
    static let cases = NamingService.allCases
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

typealias DomainName = String

extension DomainName {
    private func domainComponents() -> [String]? {
        let components = self.components(separatedBy: String.dotSeparator)
        guard components.count >= 2 else {
            Debugger.printFailure("Domain name with no deterctable NS: \(self)", critical: false)
            return nil
        }
        return components
    }
    
    func getTldName() -> String? {
        guard let tldName = domainComponents()?.last else {
            Debugger.printFailure("Couldn't get domain TLD name", critical: false)
            return nil
        }
        return tldName
    }
    
    func getBelowTld() -> String? {
        guard let domainName = domainComponents()?.dropLast(1).joined(separator: String.dotSeparator) else {
            Debugger.printFailure("Couldn't get domain name", critical: false)
            return nil
        }
        return domainName
    }
    
    static func isZilByExtension(ext: String) -> Bool {
        ext.lowercased() == NamingService.ZNS.rawValue.lowercased()
    }
}
