//
//  SendCryptoAssetNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

extension SendCryptoAsset {
    enum NavigationDestination: Hashable {
        case scanWalletAddress
        case selectAssetToSend(AssetReceiver)
        case selectTokenAmountToSend(SelectTokenAmountToSendData)
        case confirmSendToken(SendTokenAssetData)
    }
    
    struct LinkNavigationDestination {
        
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .scanWalletAddress:
                QRWalletAddressScannerView()
            case .selectAssetToSend(let receiver):
                SelectCryptoAssetToSendView(receiver: receiver)
            case .selectTokenAmountToSend(let data):
                SelectTokenAssetAmountToSendView(data: data)
            case .confirmSendToken(let data):
                ConfirmSendTokenView(data: data)
            }
        }
        
    }
}
