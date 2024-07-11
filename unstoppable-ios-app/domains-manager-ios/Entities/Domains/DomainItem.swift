//
//  Domain.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 06.10.2020.
//

import Foundation
import UIKit

struct DomainItem: DomainEntity, Codable, Equatable {
    
    var name: String
    var ownerWallet: String? = nil
    var blockchain: BlockchainType? = nil

    func inject(owner: HexAddress) -> DomainItem {
        var domainCopy = self
        domainCopy.ownerWallet = owner
        return domainCopy
    }
    
    func merge(with newDomain: DomainItem) -> DomainItem {
        var origin = self
        origin.name = newDomain.name
        origin.ownerWallet = newDomain.ownerWallet
        origin.blockchain = newDomain.blockchain
        return origin
    }
}

extension DomainItem {
    init(jsonResponse: NetworkService.DomainResponse) {
        self.name = jsonResponse.name
        self.ownerWallet = jsonResponse.ownerAddress
        self.blockchain = try? BlockchainType.getType(abbreviation: jsonResponse.blockchain)
    }
}

extension DomainItem: Hashable { }

extension DomainItem: CustomStringConvertible {
    var description: String {
        "Domain: \(name)"
    }
}

extension DomainItem: APIRepresentable {
    var apiRepresentation: String {
        "\(name)"
    }
}

// Decision methods based on DomainItem values

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
    func filterCoOwned(by ownerAddress: HexAddress, in namingService: NamingService) -> Self {
        return self.filter({$0.namingService == namingService &&  $0.ownerWallet?.normalized == ownerAddress.normalized})
    }
}

extension DomainItem {
    /// This method puts a rule whether or not the domains requires payment for a critical trnasaction.
    /// True means that the app will launch Apple Pay flow and will depend on the backend
    /// - Returns: Bool
    func doesRequirePayment() -> Bool {
        switch self.getBlockchainType() {
        case .Ethereum: return true
        default: return false
        }
    }
}
