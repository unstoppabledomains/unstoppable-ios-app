//
//  SendCryptoAssetNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

extension SendCryptoAsset {
    enum NavigationDestination: Hashable {
        case selectAssetToSend(AssetReceiver)
        case selectTokenAmountToSend(SelectTokenAmountToSendData)
        case confirmSendToken(BalanceTokenUIDescription)
    }
    
    struct LinkNavigationDestination {
        
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .selectAssetToSend(let receiver):
                SelectCryptoAssetToSendView(receiver: receiver)
            case .selectTokenAmountToSend(let data):
                SelectTokenAssetAmountToSendView(data: data)
            case .confirmSendToken(let token):
                ConfirmSendTokenView(token: token)
            }
        }
        
    }
}
