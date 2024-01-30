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
    let link: String
    let tags: [String]
    let collection: String
    let collectionLink: URL?
    let mint: String
    let traits: [Trait]
    let floorPrice: String?
    let lastSalePrice: String?
    let lastSaleDate: Date?
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
    
    var displayName: String { name ?? "-" }
    var chainIcon: UIImage { chain?.icon ?? .ethereumIcon }
   
    func loadIcon() async -> UIImage? {
        guard let imageUrl else { return nil }
        
        return await appContext.imageLoadingService.loadImage(from: .url(imageUrl, maxSize: nil),
                                                              downsampleDescription: .mid)
    }
}

// MARK: - Open methods
extension NFTDisplayInfo {
    init(nftModel: NFTModel) {
        self.name = nftModel.name
        self.description = nftModel.description
        self.imageUrl = URL(string: nftModel.imageUrl ?? "")
        self.videoUrl = nil
        self.link = nftModel.link
        self.tags = nftModel.tags ?? []
        self.collection = nftModel.collection
        self.mint = nftModel.mint
        self.chain = nftModel.chain
        self.address = nftModel.address
        self.traits = (nftModel.traits ?? [:]).map { .init(name: $0.key, value: $0.value) }
        self.collectionLink = URL(string: nftModel.collectionLink ?? "")
        self.lastSalePrice = nftModel.lastSalePrice
        self.lastSaleDate = nftModel.lastSaleDate
        self.floorPrice = nftModel.floorPriceValue
    }
}

// MARK: - Open methods
extension NFTDisplayInfo {
    enum DetailType: CaseIterable {
        case collectionID
        case chain
        case lastSaleDate
        
        var title: String {
            switch self {
            case .collectionID:
                return "Collection ID"
            case .chain:
                return "Chain"
            case .lastSaleDate:
                return "Last Updated"
            }
        }
        
        var icon: Image {
            switch self {
            case .collectionID:
                return .appleIcon
            case .chain:
                return .chainLinkIcon
            case .lastSaleDate:
                return .timeIcon
            }
        }
    }
    
    func valueFor(detailType: DetailType) -> String? {
        switch detailType {
        case .collectionID:
            return collectionLink?.absoluteString
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
        }
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
