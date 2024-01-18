//
//  NFTDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import UIKit

struct NFTDisplayInfo: Hashable, Identifiable {
    var id: String { mint ?? UUID().uuidString }
    
    let name: String?
    let description: String?
    let imageUrl: URL?
    let videoUrl: URL?
    let link: String?
    let tags: [String]
    let collection: String?
    let mint: String?
    var chain: NFTModelChain?
    var address: String?
    
    var icon: UIImage?
    
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
    
    init(nftModel: NFTModel) {
        self.name = nftModel.name
        self.description = nftModel.description
        self.imageUrl = URL(string: nftModel.imageUrl ?? "")
        self.videoUrl = URL(string: nftModel.videoUrl ?? "")
        self.link = nftModel.link
        self.tags = nftModel.tags
        self.collection = nftModel.collection
        self.mint = nftModel.mint
        self.chain = nftModel.chain
        self.address = nftModel.address
    }
    
    init(name: String? = nil, description: String? = nil, imageUrl: URL? = nil, videoUrl: URL? = nil, link: String? = nil, tags: [String], collection: String? = nil, mint: String? = nil, chain: NFTModelChain? = nil, address: String? = nil) {
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
        self.link = link
        self.tags = tags
        self.collection = collection
        self.mint = mint
        self.chain = chain
        self.address = address
    }
    
    static func mock() -> NFTDisplayInfo {
        .init(name: "NFT Name",
              description: "The MUTANT APE YACHT CLUB is a collection of up to 20,000 Mutant Apes that can only be created by exposing an existing Bored Ape to a vial of MUTANT SERUM or by minting a Mutant Ape in the public sale.",
              imageUrl: URL(string: "https://google.com"),
              tags: [],
              collection: "Collection name",
              mint: UUID().uuidString)
    }
    
    func loadIcon() async -> UIImage? {
        guard let imageUrl else { return nil }
        
//                    try? await Task.sleep(seconds: TimeInterval(arc4random_uniform(5)))
//        return UIImage.Preview.previewLandscape
                    return await appContext.imageLoadingService.loadImage(from: .url(imageUrl, maxSize: nil),
                                                                          downsampleDescription: .mid)
    }
}
