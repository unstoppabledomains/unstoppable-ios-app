//
//  SendCryptoAssetNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

extension SendCryptoAsset {
    enum NavigationDestination: Hashable {
        case selectAssetToSend
    }
    
    struct LinkNavigationDestination {
        
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .selectAssetToSend:
                SelectCryptoAssetToSendView()
            }
        }
        
    }
}