//
//  Domain.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 06.10.2020.
//

import Foundation
import UIKit

struct DomainItem: Codable {
    
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
    var claimingTxId: Int?
    var status: Status = .confirmed
    
    // TODO: - Temporary properties. Might be changed depending on implementation
    var isPrimary: Bool = false
    private(set) var isMinting: Bool = false
    var isUpdatingRecords: Bool = false
    var qrCodeURL: URL? {
        String.Links.domainProfilePage(domainName: name).url
    }
   
    func isOwned(by wallets: [UDWallet]) -> Bool {
        for wallet in wallets where isOwned(by: wallet) {
            return true
        }
        return false
    }
    
    func isOwned(by wallet: UDWallet) -> Bool {
        guard let ownerWallet = self.ownerWallet?.normalized else { return false }

        return wallet.extractEthWallet()?.address.normalized == ownerWallet || wallet.extractZilWallet()?.address.normalized == ownerWallet
    }
    
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
    
    func mergePFPInfo(with newDomain: DomainItem) -> DomainItem {
        var origin = self
        origin.pfpURL = newDomain.pfpURL
        origin.imageType = newDomain.imageType
        return origin
    }
    
    var namingService: NamingService {
        let blockchain = getBlockchainType()
        if blockchain == .Zilliqa {
            return NamingService.ZNS
        }
        return NamingService.UNS
    }
    
    func getBlockchainType() -> BlockchainType {
        if let blockchain = self.blockchain {
            return blockchain
        }
        Debugger.printWarning("Domain with no blockchain property: \(self.name)")
        return .Matic
    }
    
    var isCacheAble: Bool { !isMinting }
}

extension DomainItem {
    init(jsonResponse: NetworkService.DomainResponse) {
        self.name = jsonResponse.name
        self.ownerWallet = jsonResponse.ownerAddress
        self.blockchain = try? BlockchainType.getType(abbreviation: jsonResponse.blockchain)
        self.resolver = jsonResponse.resolver
    }
}

// MARK: - Reverse Resolution properties
extension DomainItem {
    // Do not ask to set RR if there's pending transaction
    func isReverseResolutionChangeAllowed() -> Bool {
        !isUpdatingRecords
    }
}

extension DomainItem: Hashable { }

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
    public func sign(message: String) async throws -> String {
        guard let ownerAddress = self.ownerWallet,
              let ownerWallet = appContext.udWalletsService.find(by: ownerAddress) else {
            throw NetworkLayerError.failedToFindOwnerWallet
        }
        return try await ownerWallet.getCryptoSignature(messageString: message)
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

extension DomainItem {
    enum UsageType: Equatable {
        case normal, zil, deprecated(tld: String)
    }
    
    var usageType: UsageType {
        if isZilliqaBased {
            return .zil
        } else if let tld = name.getTldName(),
                  Constants.deprecatedTLDs.contains(tld) {
            return .deprecated(tld: tld)
        }
        return .normal
    }
    var isZilliqaBased: Bool { blockchain == .Zilliqa }
    var isInteractable: Bool { usageType == .normal }
    
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
    
    func changed(domain: DomainItem) -> DomainItem? {
        if let domainInArray = self.first(where: { $0.name == domain.name }),
           domainInArray != domain {
            return domainInArray
        }
        return nil
    }
    
    mutating func remove(domains: [DomainItem]) {
        guard domains.count > 0 else { return }
        let domainNames = domains.map({$0.name})
        let indeces = self.enumerated()
            .filter({domainNames.contains($0.element.name)})
            .map({$0.offset})
        self.remove(at: indeces)
    }
    
    func interactableItems() -> [DomainItem] {
        self.filter({ $0.isInteractable })
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
    enum PFPInfo: Hashable {
        case none, nft(imageValue: String), nonNFT(imagePath: String)
        
        var value: String {
            switch self {
            case .none:
                return ""
            case .nft(let imageValue):
                return imageValue
            case .nonNFT(let imagePath):
                return imagePath
            }
        }
    }
    
    var pfpInfo: PFPInfo {
        guard let pfpURL = self.pfpURL else { return .none }
        
        switch imageType {
        case .onChain:
            return .nft(imageValue: pfpURL)
        case .offChain:
            return .nonNFT(imagePath: pfpURL)
        case .default, .none:
            return .none
        }
    }
}
