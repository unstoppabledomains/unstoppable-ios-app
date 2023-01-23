//
//  LegalType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2022.
//

import UIKit

enum LegalType: String, CaseIterable, PullUpCollectionViewCellItem {
    case termsOfUse, privacyPolicy
    
    var title: String {
        switch self {
        case .termsOfUse:
            return String.Constants.termsOfUse.localized()
        case .privacyPolicy:
            return String.Constants.privacyPolicy.localized()
        }
    }
    
    var icon: UIImage {
        switch self {
        case .termsOfUse:
            return UIImage(named: "settingsIconLegal")!
        case .privacyPolicy:
            return .infoIcon
        }
    }
    
    var analyticsName: String { rawValue }
}
