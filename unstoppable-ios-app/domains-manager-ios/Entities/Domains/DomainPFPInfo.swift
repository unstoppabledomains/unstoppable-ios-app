//
//  DomainPFPInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.12.2022.
//

import UIKit

struct DomainPFPInfo: Hashable, Codable {
    
    let domainName: String
    let pfpURL: String?
    var localImage: UIImage? = nil
    let imageType: DomainProfileImageType?
    
    enum CodingKeys: CodingKey {
        case domainName
        case pfpURL
        case imageType
    }
    
    init(domainName: String, pfpURL: String? = nil, localImage: UIImage? = nil, imageType: DomainProfileImageType? = nil) {
        self.domainName = domainName
        self.pfpURL = pfpURL
        self.localImage = localImage
        self.imageType = imageType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.domainName = try container.decode(String.self, forKey: .domainName)
        self.pfpURL = try container.decodeIfPresent(String.self, forKey: .pfpURL)
        self.imageType = try container.decodeIfPresent(DomainProfileImageType.self, forKey: .imageType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.domainName, forKey: .domainName)
        try container.encodeIfPresent(self.pfpURL, forKey: .pfpURL)
        try container.encodeIfPresent(self.imageType, forKey: .imageType)
    }
    
}

// MARK: - PFPSource
extension DomainPFPInfo {
    enum PFPSource: Hashable {
        case none, nft(imageValue: String), nonNFT(imagePath: String), local(UIImage)
        
        var value: String {
            switch self {
            case .none, .local:
                return ""
            case .nft(let imageValue):
                return imageValue
            case .nonNFT(let imagePath):
                return imagePath
            }
        }
    }
    
    var source: PFPSource {
        if let localImage {
            return .local(localImage)
        }
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

enum DomainProfileImageType: String, Codable, Hashable {
    case onChain, offChain
    case `default` /// Means no avatar is set
}
