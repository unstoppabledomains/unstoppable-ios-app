//
//  NFTDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import UIKit

struct NFTDisplayInfo: Hashable, Identifiable, Codable {
    var id: String { mint }
    
    let name: String?
    let description: String?
    let imageUrl: URL?
    var videoUrl: URL? = nil
    let link: String
    let tags: [String]
    let collection: String
    let mint: String
    let traits: [String : String]
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
        self.traits = nftModel.traits ?? [:]
    }
}
