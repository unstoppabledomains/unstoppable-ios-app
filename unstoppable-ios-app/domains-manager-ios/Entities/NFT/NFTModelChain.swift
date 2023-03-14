//
//  NFTImageChain.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import UIKit

enum NFTModelChain: String, Hashable, Codable, CaseIterable {
    case ETH
    case MATIC
    case SOL
    case ADA
    case HBAR
    
    var icon: UIImage {
        switch self {
        case .ETH:
            return .ethereumIcon
        case .MATIC:
            return .polygonIcon
        case .SOL:
            return .ethereumIcon
        case .ADA:
            return .ethereumIcon
        case .HBAR:
            return .ethereumIcon
        }
    }
}
