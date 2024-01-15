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
}

extension Array where Element == NFTModel {
    
    func clearingInvalidNFTs() -> [NFTModel] {
        func isValidField(_ field: String?) -> Bool {
            guard let field else { return false }
            
            return !field.isEmpty
        }
        
        return filter({ isValidField($0.imageUrl) || isValidField($0.videoUrl) })
    }
    
}
