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
        case selectTokenAmountToSend(BalanceTokenUIDescription)
        case confirmSendToken(BalanceTokenUIDescription)
    }
    
    struct LinkNavigationDestination {
        
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .selectAssetToSend(let receiver):
                SelectCryptoAssetToSendView(receiver: receiver)
            case .selectTokenAmountToSend(let token):
                SelectTokenAssetAmountToSendView(token: token)
            case .confirmSendToken(let token):
                ConfirmSendTokenView(token: token)
            }
        }
        
    }
}
