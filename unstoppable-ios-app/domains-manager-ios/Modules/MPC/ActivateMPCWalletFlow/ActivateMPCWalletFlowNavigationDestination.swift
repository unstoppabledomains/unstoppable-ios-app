//
//  ActivateMPCWalletFlowNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

extension ActivateMPCWalletFlow {
    enum NavigationDestination: Hashable {
        case signInWithEmail
        case checkout
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .signInWithEmail:
                PurchaseMPCWalletAuthEmailView()
            case .checkout:
                PurchaseMPCWalletCheckoutView()
            }
        }
    }
}
