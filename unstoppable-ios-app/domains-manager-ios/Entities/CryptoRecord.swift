//
//  CryptoRecord.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.05.2022.
//

import Foundation

enum RecordToUpdate: Hashable {
    static let socialPictureKey = "social.picture.value"
    static let ipfsKey = "ipfs.html.value"
    
    case crypto (CryptoRecord)
    case web3 (String)
    case pictureValue (String)
    
    func resolveKey() -> String {
        switch self {
        case .crypto(let cryptoRecord): return cryptoRecord.coin.expandedTicker
        case .pictureValue: return Self.socialPictureKey
        case .web3: return Self.ipfsKey
        }
    }
    
    func resolveValue() -> String {
        switch self {
        case .crypto(let cryptoRecord): return cryptoRecord.address
        case .pictureValue(let value): return value
        case .web3(let value): return value
        }
    }
}

struct CryptoRecord: Hashable, Comparable, Codable {
    let coin: CoinRecord
    var address: String
    var isDeprecated: Bool { coin.isDeprecated }
    
    init(coin: CoinRecord, address: String = "") {
        self.coin = coin
        self.address = address
    }
    
    init?(coin: CoinRecord?, address: String) {
        guard let coin = coin else { return nil }
        
        self.init(coin: coin, address: address)
    }
    
    static func < (lhs: CryptoRecord, rhs: CryptoRecord) -> Bool {
        lhs.coin < rhs.coin
    }
  
    func validate(address: String) -> RecordError? {
        let isValid = coin.validate(address)
        return isValid ? nil : RecordError.invalidAddress
    }
    
    func validate() -> RecordError? {
        validate(address: address)
    }
}

extension CryptoRecord {
    enum RecordError: Error {
        case invalidAddress
        
        var title: String {
            switch self {
            case .invalidAddress:
                return String.Constants.manageDomainInvalidAddressError.localized()
            }
        }
    }
}
