//
//  DomainPFPInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.12.2022.
//

import Foundation

struct DomainPFPInfo: Hashable, Codable {
    let domainName: String
    let pfpURL: String?
    let imageType: DomainProfileImageType?
}

// MARK: - PFPSource
extension DomainPFPInfo {
    enum PFPSource: Hashable {
        case none, nft(imageValue: String), nonNFT(imagePath: String)
        
        var value: String {
            switch self {
            case .none:
                return ""
            case .nft(let imageValue):
                return imageValue
            case .nonNFT(let imagePath):
                return imagePath
            }
        }
    }
    
    var source: PFPSource {
        guard let pfpURL = self.pfpURL else { return .none }
        
        switch imageType {
        case .onChain:
            return .nft(imageValue: pfpURL)
        case .offChain:
            return .nonNFT(imagePath: pfpURL)
        case .default, .none:
            return .none
        }
    }
}
