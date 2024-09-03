//
//  CryptoEditingGroupedRecord.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.09.2022.
//

import Foundation

struct CryptoEditingGroupedRecord: Hashable {
    
    private(set) var records: [CryptoRecord] { didSet { setPrimaryIndex() } }
    private var primaryRecordIndex: Int = 0
    var primaryRecord: CryptoRecord { records[primaryRecordIndex] }
    var isEditing: Bool = false
    var bufferAddress: String = ""
    var isRemovable = true
    
    var debugPrimaryRecord: CryptoRecord? { records.first(where: { $0.coin.isPrimaryChain })} // For debug purposes
    var isMultiChain: Bool { records.count > 1 }
    var currencies: [CoinRecord] { records.reduce(into: [CoinRecord](), { $0.append($1.coin) }) }
    var isDeprecated: Bool { records.filter({ !$0.isDeprecated }).isEmpty } // If there's no NOT deprecated coins
    
    init(records: [CryptoRecord]) {
        self.records = records.sorted()
        self.bufferAddress = primaryRecord.address
        setPrimaryIndex()
    }
    
    var primaryMultiChainRecord: CryptoRecord {
        if !primaryRecord.address.isEmpty {
            return primaryRecord
        } else {
            return recordsWithValidAddresses.first ?? primaryRecord;
        }
    }
    
    mutating func updateRecords(_ records: [CryptoRecord]) {
        self.records = records.sorted()
        self.bufferAddress = primaryRecord.address
    }
    
    mutating func resolveBufferAddress() {
        records[primaryRecordIndex].address = bufferAddress
    }
    
    mutating func clear() {
        for i in 0..<records.count {
            records[i].address = ""
        }
        bufferAddress = ""
    }
    
    mutating func removeEmptyChains() {
        let nonEmptyRecords = records.filter({ !$0.address.isEmpty }).sorted()
        if !nonEmptyRecords.isEmpty {
            self.records = nonEmptyRecords
        }
    }
    
    mutating func removeUnchangedRecords(comparing groupedRecord: CryptoEditingGroupedRecord) {
        guard isMultiChain else { return }
        
        self.records = self.records.filter({ record in
            if let compareRecord = groupedRecord.records.first(where: { $0.coin.expandedTicker == record.coin.expandedTicker }),
               compareRecord.address != record.address {
                return true
            }
            return false
        })
    }
    
    var isValidInput: Bool {
        addressValidationError() == nil
    }
    
    func addressValidationError() -> CryptoRecord.RecordError? {
        let nonEmptyAddressRecords = records.filter({ !$0.address.isEmpty })
        if nonEmptyAddressRecords.isEmpty {
            if isRemovable {
                // User didn't fill any address
                return .invalidAddress
            } else {
                // Non removable records don't produce any error if empty.
                return nil
            }
        }
        
        let errors = nonEmptyAddressRecords.compactMap({ record -> CryptoRecord.RecordError? in
            record.validate()
        })
        
        // Some of entered addresses having issues
        return errors.first
    }
    
    var recordsWithValidAddresses: [CryptoRecord] {
        records.filter({ $0.validate() == nil && !$0.address.isEmpty })
    }
    
    var validAddresses: [String] {
        recordsWithValidAddresses.map({ $0.address })
    }
    
    private mutating func setPrimaryIndex() {
        primaryRecordIndex = records.firstIndex(where: { $0.coin.isPrimaryChain }) ?? 0
    }
}

extension CryptoEditingGroupedRecord {
    static func getGroupIdentifierFor(coin: CoinRecord) -> String {
        coin.ticker
    }
    
    static func groupCoins(_ coins: [CoinRecord]) -> [String : [CoinRecord]] {
        [String : [CoinRecord]].init(grouping: coins, by: { getGroupIdentifierFor(coin: $0) })
    }
}
