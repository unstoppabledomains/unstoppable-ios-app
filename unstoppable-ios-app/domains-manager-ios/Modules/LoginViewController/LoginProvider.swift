//
//  LoginProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.01.2024.
//

import UIKit

enum LoginProvider: String, Hashable, Codable, CaseIterable, PullUpCollectionViewCellItem {
    
    case email, google, twitter, apple
    
    var title: String {
        switch self {
        case .email:
            return "Email"
        case .google:
            return "Google"
        case .twitter:
            return "Twitter"
        case .apple:
            return "Apple"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .email:
            return .mailIcon24
        case .google:
            return .googleIcon24
        case .twitter:
            return .twitterIcon24
        case .apple:
            return .appleIcon
        }
    }
    
    var analyticsName: String { rawValue }
}
