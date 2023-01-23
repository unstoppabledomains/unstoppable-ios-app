//
//  WalletViewTransactionsAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.05.2022.
//

import UIKit

enum WalletViewTransactionsAction: String, CaseIterable, PullUpCollectionViewCellItem {
    
    case ethereum, polygon
    
    var title: String {
        switch self {
        case .ethereum:
            return String.Constants.ethereumTransactions.localized()
        case .polygon:
            return String.Constants.polygonTransactions.localized()
        }
    }
    
    var icon: UIImage {
        switch self {
        case .ethereum:
            return .ethereumIcon
        case .polygon:
            return .polygonIcon
        }
    }
    
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { .topRight }
    var analyticsName: String { rawValue }
    
}


