//
//  CryptoEditingGroupedRecordsChangesCalculator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.09.2022.
//

import Foundation

struct CryptoEditingGroupedRecordsChangesCalculator {
    func calculateRecordChangesBetween(editingGroupedRecords: [CryptoEditingGroupedRecord],
                              groupedRecords: [CryptoEditingGroupedRecord]) -> (inserted: [CryptoEditingGroupedRecord], removed: [CryptoEditingGroupedRecord], changed: [CryptoEditingGroupedRecord]) {
        let difference = editingGroupedRecords.difference(from: groupedRecords)
        
        var inserted = [CryptoEditingGroupedRecord]()
        var removed = [CryptoEditingGroupedRecord]()
        var changed = [CryptoEditingGroupedRecord]()
        
        for change in difference {
            switch change {
            case let .remove(_, element, _):
                removed.append(element)
            case let .insert(_, element, _):
                inserted.append(element)
            }
        }
        
        for i in stride(from: inserted.count - 1, to: -1, by: -1) {
            var insertedElement = inserted[i]
            
            if let j = removed.firstIndex(where: { $0.primaryRecord.coin == insertedElement.primaryRecord.coin }) {
                if insertedElement.records.map({ $0.address }) != removed[j].records.map({ $0.address }) {
                    insertedElement.removeUnchangedRecords(comparing: removed[j])
                    
                    func removeAtIndexes() {
                        inserted.remove(at: i)
                        removed.remove(at: j)
                    }
                    
                    if Constants.nonRemovableDomainCoins.contains(insertedElement.primaryRecord.coin.ticker) {
                        /// User able to set empty address to certain coins.
                        if insertedElement.records.first(where: { !$0.address.isEmpty }) == nil {
                            /// If address were not empty and user set it as empty, it's not considered as incorrect but as removed
                            removeAtIndexes()
                            removed.append(insertedElement)
                        } else if removed[j].records.first(where: { !$0.address.isEmpty }) == nil,
                                  insertedElement.records.first(where: { $0.address.isEmpty }) == nil {
                            /// If address were empty and user set some address, it is considered as added
                            removeAtIndexes()
                            inserted.append(insertedElement)
                        } else {
                            removeAtIndexes()
                            changed.append(insertedElement)
                        }
                    } else {
                        removeAtIndexes()
                        changed.append(insertedElement)
                    }
                }
            }
        }
        
        return (inserted, removed, changed)
    }
    
    func calculateChangedRecordsToSaveBetween(editingGroupedRecords: [CryptoEditingGroupedRecord],
                                              groupedRecords: [CryptoEditingGroupedRecord]) -> (inserted: [CryptoEditingGroupedRecord], removed: [CryptoEditingGroupedRecord], changed: [CryptoEditingGroupedRecord]) {
        var (inserted, removed, changed) = calculateRecordChangesBetween(editingGroupedRecords: editingGroupedRecords,
                                                                         groupedRecords: groupedRecords)
        
        for i in 0..<removed.count {
            removed[i].clear()
        }
        
        for i in 0..<inserted.count {
            if inserted[i].isMultiChain {
                inserted[i].removeEmptyChains()
            }
        }
        
        return (inserted, removed, changed)
    }
    
    func calculateRecordChangesByTypeBetween(editingGroupedRecords: [CryptoEditingGroupedRecord],
                                    groupedRecords: [CryptoEditingGroupedRecord]) -> [RecordChangeType] {
        let (inserted, removed, changed) = calculateRecordChangesBetween(editingGroupedRecords: editingGroupedRecords,
                                                                groupedRecords: groupedRecords)
        
        return inserted.map({ RecordChangeType.added($0.primaryMultiChainRecord) }) + removed.map({ RecordChangeType.removed($0.primaryMultiChainRecord) }) + changed.map({ RecordChangeType.updated($0.primaryMultiChainRecord) })
    }
}
