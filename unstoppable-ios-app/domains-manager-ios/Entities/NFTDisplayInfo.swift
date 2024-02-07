//
//  NFTDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct NFTDisplayInfo: Hashable, Identifiable, Codable {
    var id: String { mint }
    
    let name: String?
    let description: String?
    let imageUrl: URL?
    var videoUrl: URL? = nil
    var link: URL? = nil
    let tags: [String]
    let collection: String
    let collectionLink: URL?
    let mint: String
    let traits: [Trait]
    var floorPriceDetails: FloorPriceDetails? = nil
    var lastSaleDetails: SaleDetails? = nil
    var rarity: String?
    var acquiredDate: Date?

    var chain: NFTModelChain?
    var address: String?
    
    var isDomainNFT: Bool { tags.contains("domain") }
    var isUDDomainNFT: Bool {
        if isDomainNFT,
           let tld = name?.components(separatedBy: ".").last,
           User.instance.getAppVersionInfo().tlds.contains(tld) {
            return true
        }
        return false
    }
    var lastSalePrice: String? {
        guard let lastSaleDetails else { return nil }
        
        return "\(lastSaleDetails.valueNative) \(lastSaleDetails.symbol)"
    }
    var lastSaleDate: Date? { lastSaleDetails?.date }

    var displayName: String { name ?? "-" }
    var chainIcon: UIImage { chain?.icon ?? .ethereumIcon }
   
    func loadIcon() async -> UIImage? {
        guard let imageUrl else { return nil }
        
        return await appContext.imageLoadingService.loadImage(from: .url(imageUrl, maxSize: nil),
                                                              downsampleDescription: .mid)
    }
    
    struct SaleDetails: Codable, Hashable {
        let date: Date
        let symbol: String
        let valueUsd: Double
        let valueNative: Double
    }
    
    struct FloorPriceDetails: Codable, Hashable {
        let value: Double
        let currency: String
    }
}

// MARK: - Open methods
extension NFTDisplayInfo {
    init(nftModel: NFTModel) {
        self.name = nftModel.name
        self.description = nftModel.description
        self.imageUrl = URL(string: nftModel.imageUrl ?? "")
        self.videoUrl = nil
        self.link = URL(string: nftModel.link)
        self.tags = nftModel.tags ?? []
        self.collection = nftModel.collection
        self.mint = nftModel.mint
        self.chain = nftModel.chain
        self.address = nftModel.address
        self.traits = (nftModel.traits ?? [:]).map { .init(name: $0.key, value: $0.value) }
        self.collectionLink = URL(string: nftModel.collectionLink ?? "")
        if let lastSaleDetails = nftModel.lastSaleTransaction {
            let payment = lastSaleDetails.payment!
            self.lastSaleDetails = SaleDetails(date: lastSaleDetails.date!,
                                               symbol: payment.symbol!, valueUsd: payment.valueUsd!, valueNative: payment.valueNative!)
        }
        if let floorPrice = nftModel.floorPrice,
           let currency = floorPrice.currency,
           let value = floorPrice.value {
            self.floorPriceDetails = FloorPriceDetails(value: value, currency: currency)
        }
        if let rank = nftModel.rarity?.rank,
           let supply = nftModel.supply {
            self.rarity = "\(rank) / \(supply)"
        }
        self.acquiredDate = nftModel.acquiredDate
    }
}

// MARK: - Open methods
extension NFTDisplayInfo {
    enum DetailType: CaseIterable {
        case collectionID
        case tokenID
        case chain
        case rarity
        case lastSaleDate
        case holdDays
        
        var title: String {
            switch self {
            case .collectionID:
                return String.Constants.collectionID.localized()
            case .tokenID:
                return String.Constants.tokenID.localized()
            case .chain:
                return String.Constants.chain.localized()
            case .lastSaleDate:
                return String.Constants.lastUpdated.localized()
            case .rarity:
                return String.Constants.rarity.localized()
            case .holdDays:
                return String.Constants.holdDays.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .collectionID:
                return Image(systemName: "number")
            case .tokenID:
                return Image(systemName: "number")
            case .chain:
                return Image(systemName: "link")
//                return .chainLinkIcon
            case .lastSaleDate:
                return Image(systemName: "clock")
//                return .timeIcon
            case .rarity:
                return Image(systemName: "sparkles")
            case .holdDays:
                return Image(systemName: "calendar")
            }
        }
    }
    
    func valueFor(detailType: DetailType) -> String? {
        switch detailType {
        case .collectionID:
            return collectionLink?.absoluteString
        case .tokenID:
            return link?.lastPathComponent
        case .chain:
            return chain?.fullName
        case .lastSaleDate:
            if let lastSaleDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                formatter.dateTimeStyle = .named
                return formatter.localizedString(for: lastSaleDate, relativeTo: Date()).capitalizedFirstCharacter
            }
            return nil
        case .rarity:
            return rarity
        case .holdDays:
            if let acquiredDate,
            let days = Calendar.current.dateComponents([.day], from: acquiredDate, to: Date()).day {
                return String(days)
            }
        }
        return nil
    }
}

// MARK: - Open methods
extension NFTDisplayInfo {
    struct Trait: Identifiable, Hashable, Codable {
        var id: String { name }
        
        let name: String
        let value: String
    }
}
