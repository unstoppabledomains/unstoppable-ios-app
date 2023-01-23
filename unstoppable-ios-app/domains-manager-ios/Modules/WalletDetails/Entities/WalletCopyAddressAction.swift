//
//  WalletCopyAddressAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.05.2022.
//

import UIKit

enum WalletCopyAddressAction: PullUpCollectionViewCellItem {
    
    case ethereum(address: String), zil(address: String)
    
    var title: String {
        switch self {
        case .ethereum:
            return String.Constants.ethAddress.localized()
        case .zil:
            return String.Constants.zilAddress.localized()
        }
    }
    
    var subtitle: String? {
        switch self {
        case .ethereum(let address):
            return address.walletAddressTruncated
        case .zil(let address):
            return address.walletAddressTruncated
        }
    }
    
    var icon: UIImage {
        switch self {
        case .ethereum:
            return .ethereumIcon
        case .zil:
            return .zilIcon
        }
    }
    
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { .copyToClipboard }
    var analyticsName: String {
        switch self {
        case .ethereum: return "ethereum"
        case .zil: return "zil"
        }
    }
}
