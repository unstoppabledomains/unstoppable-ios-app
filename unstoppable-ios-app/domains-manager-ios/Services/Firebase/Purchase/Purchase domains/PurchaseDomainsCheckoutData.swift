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
    var purchaseLocation: UserPurchaseLocation = .other
    
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
    
    var discountCodeIfEntered: String? { discountCode.isEmpty ? nil : discountCode }
    var zipCodeIfEntered: String? {
        switch purchaseLocation {
        case .usa:
            return usaZipCode.isEmpty ? nil : usaZipCode
        case .other:
            return nil
        }
    }
    
    enum UserPurchaseLocation: String, Codable, CaseIterable {
        case usa
        case other
    }
}

extension PurchaseDomainsCheckoutData: Codable {
    enum CodingKeys: String, CodingKey {
        case isStoreCreditsOn
        case isPromoCreditsOn
        case usaZipCode
        case discountCode
        case durationsMap
        case purchaseLocation
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isStoreCreditsOn, forKey: .isStoreCreditsOn)
        try container.encode(isPromoCreditsOn, forKey: .isPromoCreditsOn)
        try container.encode(usaZipCode, forKey: .usaZipCode)
        try container.encode(discountCode, forKey: .discountCode)
        try container.encode(durationsMap, forKey: .durationsMap)
        try container.encode(purchaseLocation, forKey: .purchaseLocation)
    }
    
    // Implement the init(from:) method
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isStoreCreditsOn = try container.decode(Bool.self, forKey: .isStoreCreditsOn)
        isPromoCreditsOn = try container.decode(Bool.self, forKey: .isPromoCreditsOn)
        usaZipCode = try container.decode(String.self, forKey: .usaZipCode)
        discountCode = try container.decode(String.self, forKey: .discountCode)
        durationsMap = try container.decode([String: Double].self, forKey: .durationsMap)
        
        let purchaseLocation = try? container.decode(UserPurchaseLocation.self, forKey: .purchaseLocation)
        if let purchaseLocation {
            self.purchaseLocation = purchaseLocation
        } else {
            self.purchaseLocation = usaZipCode.isEmpty ? .other : .usa
        }
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
