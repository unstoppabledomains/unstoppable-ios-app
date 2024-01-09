//
//  TransactionItem.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 15.10.2020.
//

import Foundation
import BigInt

enum TxType: String, Codable {
    case zilTx = "ZilTx"
    case ethTx = "EthTx"
    case maticTx = "MaticTx"
}

enum TxStatusGroup: String, Codable {
    case pending = "Pending"
    case completed = "Completed"
    case failed = "Failed"
}

struct TransactionItem: Codable {
    static let cnsConfirmationBlocksBLOCKS: UInt64 = 12
    var id: UInt64?
    var transactionHash: HexAddress?
    var domainName: String?
    
    private(set) var isPending: Bool
    
    var type: TxType?
    var operation: TxOperation?
    
    var gasPrice: Gwei?
    var nonce: Int?
    
    var domainId: HexAddress?
    var blockHash: HexAddress?
    var blockNumber: HexAddress?
    
    var logs: [ResponseLog]?
    
    init(id: UInt64? = nil, transactionHash: HexAddress? = nil, domainName: String?,
         isPending: Bool, type: TxType? = nil, operation: TxOperation? = nil,
         gasPrice: Gwei? = nil, nonce: Int? = nil,
         domainId: HexAddress? = nil) {
        if transactionHash == nil && id == nil {
            Debugger.printFailure("Tx must have at least a hash or an id", critical: true)
        }

        self.id = id
        self.transactionHash = transactionHash
        self.domainName = domainName
        self.isPending = isPending
        self.gasPrice = gasPrice
        self.nonce = nonce
        
        self.domainId = domainId
        self.operation = operation
        self.type = type
    }
    
    init (jsonResponse: NetworkService.TxResponse) {
        let isPending = TxStatusGroup(rawValue: jsonResponse.statusGroup) == .pending
        self.init(id: jsonResponse.id,
                  transactionHash: jsonResponse.hash,
                  domainName: jsonResponse.domain.name,
                  isPending:  isPending,
                  type: jsonResponse.type,
                  operation: jsonResponse.operation)
    }
    
    private func parseNameId(_ tx: TransactionItem) -> (String?, HexAddress?) {
        var name: String?
        var tokenId: HexAddress?

        tx.logs?.forEach {
            if let type = EventType(rawValue: $0.topics[0]),
               !Self.typesToAvoid.contains(type){
                tokenId = $0.topics[type.domainIdFieldIndex] }
            
            if $0.data.count > 0,
               !$0.data.isEmpty,
               $0.data != "0x" {
                name = $0.data.hexToAscii
            }
        }
        return (name, tokenId)
    }
    
    func merge(withNew newTx: TransactionItem, latestBlockNumber: BigUInt? = nil) -> TransactionItem {
        var original = self
        
        if original.transactionHash == nil, let newHash = newTx.transactionHash {
            original.transactionHash = newHash
        }
        
        if original.id == nil, let newId = newTx.id {
            original.id = newId
        }
                
        if let latestBlock = latestBlockNumber {
            if let block = newTx.blockNumber?.hexToDec {
                original.isPending = block + Self.cnsConfirmationBlocksBLOCKS >= latestBlock
            }
        } else {
            original.isPending = newTx.isPending
        }
        
        if original.domainName == nil, let newName = newTx.domainName {
            original.domainName = newName
        }
        
        if original.type == nil, let newType = newTx.type {
            original.type = newType
        }
        
        if original.operation == nil, let newOperation = newTx.operation {
            original.operation = newOperation
        }
        
        if original.blockHash == nil, let newBlockHash = newTx.blockHash {
            original.blockHash = newBlockHash
        }
        
        if original.blockNumber == nil, let newBlockNumber = newTx.blockNumber {
            original.blockNumber = newBlockNumber
        }
        
        if let newLogs = newTx.logs {
            original.logs = newLogs
            
            let nameId = parseNameId(newTx)
            
            if let logDomainName = nameId.0 {
                if original.domainName == nil {
                    original.domainName = logDomainName
                }
            }
            
            if let logDomainId = nameId.1 {
                if original.domainId == nil {
                    original.domainId = logDomainId
                }
            }
        }
        return original
    }
    
    func isPendingFor(_ domain: DomainItem) -> Bool {
        guard self.isPending else { return false }
        
        switch domain.namingService {
        case .UNS: return domainName == domain.name
        case .ZNS: return self.isPendingZilDomain(domain)
        }
    }
    
    private func isPendingZilDomain(_ domain: DomainItem) -> Bool {
        guard let ownerAddress = domain.ownerWallet?.normalized,
              let pendingDomainName = self.domainName else { return true }
        
        let pendingDomains = Storage.instance.findDomains(by: [pendingDomainName])
        let pendingWallets = pendingDomains.compactMap{ $0.ownerWallet?.normalized }
        return pendingWallets.contains(ownerAddress)
    }
    
    func isMintingTransaction() -> Bool {
        guard self.operation != .mintDomain else { return true }
        
        let mintingIds = MintingDomainsStorage.retrieveMintingDomains().map({$0.transactionId})
        guard let selfId = self.id else { return false }
        return operation == .transferDomain && mintingIds.contains(selfId)
    }
}

extension TransactionItem: Equatable {
    static func == (lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        if lhs.transactionHash != nil, rhs.transactionHash != nil,
            !lhs.transactionHash!.isEmpty && !rhs.transactionHash!.isEmpty {
            return lhs.transactionHash!.normalized == rhs.transactionHash!.normalized
        }
        if lhs.id != nil, rhs.id != nil {
            return lhs.id! == rhs.id!
        }
        Debugger.printFailure("Transactions: 1. (hash = \(String(describing: lhs.transactionHash)), id = \(String(describing: lhs.id))) and 2. (hash = \(String(describing: rhs.transactionHash)), id = \(String(describing: rhs.id))) are not comparable", critical: false)
        return false
    }
}

extension TransactionItem: CustomStringConvertible {
    var description: String {
        "ID: \(id ?? 0), pending: \(isPending) | domain:\(String(describing: domainName)) | TxOperation \(String(describing: operation)) | TX: hash: \(transactionHash ?? "null")\n"
    }
}

extension TransactionItem {
    static let typesToAvoid = [EventType.NewKey]
    
    enum EventType: HexAddress, Codable {
        case Transfer = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
        case NewURI = "0xc5beef08f693b11c316c0c8394a377a0033c9cf701b8cd8afd79cecef60c3952"
        
        case SetRecord = "0x851ffe8e74d5015261dba0a1f9e1b0e5d42c5af5d2ad1908fee897c7d80a0d92"
        case NewKey = "0x7ae4f661958fbecc2f77be6b0eb280d2a6f604b29e1e7221c82b9da0c4af7f86"
        case ResetRecords = "0x185c30856dadb58bf097c1f665a52ada7029752dbcad008ea3fefc73bee8c9fe"
        
        var signatureHash: HexAddress {
            return rawValue
        }
        
        var domainIdFieldIndex: Int {
            switch self {
            case .Transfer: return 3
            case .NewURI: return 1
            case .SetRecord: return 2
            case .ResetRecords: return 0
            case .NewKey: fatalError()
            }
        }
        
        var name: String {
            switch self {
            case .Transfer: return "Transfer"
            case .NewURI: return "NewURI"
            case .SetRecord: return "SetRecord"
            case .ResetRecords: return "ResetRecords"
            case .NewKey: return "NewKey"
            }
        }
    }
}

extension Array where Element == TransactionItem {
    func containPending(_ domain: DomainItem) -> Bool {
        first(where: { $0.isPendingFor(domain) }) != nil 
    }
    
    func containMintingInProgress(_ domain: DomainItem) -> Bool {
        filterPending { transaction in
            transaction.isMintingTransaction()
        }.first(where: { $0.domainName == domain.name }) != nil
    }
    
    func filterPending(extraCondition: ( (TransactionItem) -> Bool) = { _ in true }) -> Self {
        self.filter({ $0.isPending && extraCondition($0) })
    }
}
