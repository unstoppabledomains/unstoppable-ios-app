//
//  QRScannerHint.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import UIKit

enum QRScannerHint {
    case walletConnect
    case walletAddress
    
    var title: String {
        switch self {
        case .walletConnect:
            return String.Constants.walletConnectCompatible.localized()
        case .walletAddress:
            return String.Constants.scanWalletAddressHint.localized()
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .walletConnect:
            return .externalWalletIndicator
        case .walletAddress:
            return nil
        }
    }
}
