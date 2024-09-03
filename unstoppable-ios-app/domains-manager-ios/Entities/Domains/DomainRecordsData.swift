//
//  DomainRecordsData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

struct DomainRecordsData: Equatable, Codable {
    var records: [CryptoRecord]
    let resolver: String?
    let ipfsRedirectUrl: String?
    
    static let empty = DomainRecordsData(from: [:], coinRecords: [], resolver: nil)
     
    init(from recordsDict: [String: String], coinRecords: [CoinRecord], resolver: String?) {
        let cryptoRecords: [CryptoRecord] = recordsDict.compactMap { dictElement in
            let expandedTicker = dictElement.key
            guard let coinRecord = coinRecords.first(where: { $0.isMatching(recordKey: expandedTicker) }) else {
                Debugger.printWarning("Ignored record with key: \(expandedTicker)")
                return nil
            }
            return CryptoRecord(coin: coinRecord,
                                address: dictElement.value)
        }
        
        // Remove duplicates after mapping old and new record structures 
        self.records = Set(cryptoRecords).filter({ !$0.address.isEmpty })
        self.resolver = resolver
        self.ipfsRedirectUrl = recordsDict[NetworkService.ipfsRedirectKey]
    }
}
