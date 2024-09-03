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
        let cryptoRecords: [CryptoRecord] = recordsDict
            .compactMap { Self.transformToCryptoRecord(dictElement: $0, in: coinRecords) }
            .filter({ !$0.address.isEmpty })
        
        /// Removes duplicates after merging
        let groupedRecords = [CoinRecord : [CryptoRecord]].init(grouping: cryptoRecords, by: { $0.coin })
        let records: [CryptoRecord] = groupedRecords.reduce([CryptoRecord](), { $0 + [$1.value.first!] })
        
        self.records = records
        self.resolver = resolver
        self.ipfsRedirectUrl = recordsDict[NetworkService.ipfsRedirectKey]
    }
    
    private static func transformToCryptoRecord(dictElement: [String : String].Element, 
                                                in coinRecords: [CoinRecord]) -> CryptoRecord? {
        let expandedTicker = dictElement.key
        guard let coinRecord = coinRecords.first(where: { $0.isMatching(recordKey: expandedTicker) }) else {
            Debugger.printWarning("Ignored record with key: \(expandedTicker)")
            return nil
        }
        return CryptoRecord(coin: coinRecord,
                            address: dictElement.value)
    }
}
