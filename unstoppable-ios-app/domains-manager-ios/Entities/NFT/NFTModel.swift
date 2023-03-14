//
//  NFTModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import UIKit

struct NFTModel: Codable, Hashable {
    var name: String?
    var description: String?
    var imageUrl: String?
    var `public`: Bool
    var videoUrl: String?
    var link: String?
    var tags: [String]
    var collection: String?
    var mint: String?
    var chain: NFTModelChain?
    var address: String?
    
    var isDomainNFT: Bool { tags.contains("domain") }
    
    var chainIcon: UIImage { chain?.icon ?? .ethereumIcon }
}
