//
//  NFTModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import UIKit

struct NFTModel: Codable, Hashable {
    let mint: String
    let link: String
    let collection: String
    let collectionOwners: Int?
    let collectionLink: URL?
    let name: String?
    let description: String?
    let imageUrl: String?
    let tags: [String]?
    let createdDate: String?
    let acquiredDate: String?
    let saleDetails: SaleDetails?
    let floorPrice: FloorPrice?
    let traits: [String : String]?
    let supply: Int?
    let isPublic: Bool
    var chain: NFTModelChain?
    var address: String?
    
    enum CodingKeys: String, CodingKey {
        case mint, link, collection, collectionOwners, collectionLink, name, description, tags, createdDate, acquiredDate, saleDetails, floorPrice, traits, supply
        case imageUrl = "image_url"
        case isPublic = "public"
    }
   
    var lastSalePrice: String? {
        let saleTransactions = ([saleDetails?.primary] + (saleDetails?.secondary ?? [])).compactMap { $0 }
        if let latestPrice = saleTransactions.filter({ $0.date != nil && $0.payment?.symbol != nil && $0.payment?.valueNative != nil }).sorted(by: { $0.date! > $1.date! }).first(where: { $0.payment != nil }) {
            let symbol = latestPrice.payment!.symbol!
            let value = latestPrice.payment!.valueNative!
            return "\(value) \(symbol)"
        }
        return nil
    }
    
    
    var floorPriceValue: String? {
        if let floorPrice,
           let currency = floorPrice.currency,
           let value = floorPrice.value {
            return "\(value) \(currency)"
        }
        return nil
    }
}

extension NFTModel {
    struct SaleDetails: Codable, Hashable {
        let primary: SaleTransaction
        let secondary: [SaleTransaction]?
    }
    
    struct SaleTransaction: Codable, Hashable {
        let type: String?
        let date: Date?
        let cost: Double?
        let txHash: String?
        let marketPlace: String?
        let payment: PaymentDetails?
    }
    
    struct PaymentDetails: Codable, Hashable {
        let symbol: String?
        let valueUsd: Double?
        let valueNative: Double?
    }
    
    struct FloorPrice: Codable, Hashable {
        let currency: String?
        let value: Double?
    }
}

extension Array where Element == NFTModel {
    
    func clearingInvalidNFTs() -> [NFTModel] {
        func isValidField(_ field: String?) -> Bool {
            guard let field else { return false }
            
            return !field.isEmpty
        }
        
        return filter({ isValidField($0.imageUrl) })
    }
    
}
