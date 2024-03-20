//
//  SendCryptoNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

enum SendCryptoNavigationDestination: Hashable {
    case selectAssetToSend
}

struct SendCryptoLinkNavigationDestination {
    
    @ViewBuilder
    static func viewFor(navigationDestination: SendCryptoNavigationDestination) -> some View {
        switch navigationDestination {
        case .selectAssetToSend:
            SelectAssetToSendView()
        }
    }
    
}
