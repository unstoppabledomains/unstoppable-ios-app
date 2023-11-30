//
//  PurchaseDomainsCheckoutData.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

struct PurchaseDomainsCheckoutData: Equatable {
    var isStoreCreditsOn: Bool = true
    var isPromoCreditsOn: Bool = true
    var usaZipCode: String = ""
    var discountCode: String = ""
    var durationsMap: [String : Double] = [:]
    
    func getDurationsMapString() -> String {
        if durationsMap.isEmpty {
            return ""
        }
        guard let data = durationsMap.jsonData(),
              let str = String(data: data, encoding: .utf8) else {
            return ""
        }
        return str
    }
    
}

extension PurchaseDomainsCheckoutData: Codable {
    enum CodingKeys: String, CodingKey {
        case isStoreCreditsOn
        case isPromoCreditsOn
        case usaZipCode
        case discountCode
        case durationsMap
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isStoreCreditsOn, forKey: .isStoreCreditsOn)
        try container.encode(isPromoCreditsOn, forKey: .isPromoCreditsOn)
        try container.encode(usaZipCode, forKey: .usaZipCode)
        try container.encode(discountCode, forKey: .discountCode)
        try container.encode(durationsMap, forKey: .durationsMap)
    }
    
    // Implement the init(from:) method
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isStoreCreditsOn = try container.decode(Bool.self, forKey: .isStoreCreditsOn)
        isPromoCreditsOn = try container.decode(Bool.self, forKey: .isPromoCreditsOn)
        usaZipCode = try container.decode(String.self, forKey: .usaZipCode)
        discountCode = try container.decode(String.self, forKey: .discountCode)
        durationsMap = try container.decode([String: Double].self, forKey: .durationsMap)
    }
}

extension PurchaseDomainsCheckoutData: RawRepresentable {
    public init?(rawValue: String) {
        if let entity = PurchaseDomainsCheckoutData.objectFromJSONString(rawValue) {
            self = entity
        } else {
            return nil
        }
    }
    
    public var rawValue: String {
        return self.jsonString() ?? ""
    }
}
