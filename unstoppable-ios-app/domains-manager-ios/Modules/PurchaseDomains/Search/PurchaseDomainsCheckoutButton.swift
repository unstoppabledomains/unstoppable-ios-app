//
//  PurchaseDomainsCheckoutButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2024.
//

import SwiftUI

struct PurchaseDomainsCheckoutButton: ViewModifier {
    
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel
    @EnvironmentObject private var localCart: PurchaseDomains.LocalCart
    
    func body(content: Content) -> some View {
        VStack {
            content
            
            if !localCart.domains.isEmpty {
                UDButtonView(text: String.Constants.checkout.localized(),
                             subtext: subtitle,
                             style: .large(.raisedPrimary)) {
                    if localCart.isShowingCart {
                        localCart.isShowingCart = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: didConfirmToCheckout)
                    } else {
                        didConfirmToCheckout()
                    }
                }
                             .padding(.horizontal, 16)
            }
        }
    }
    
    private var subtitle: String {
        "\(String.Constants.totalDue.localized()): \(formatCartPrice(localCart.totalPrice))"
    }
    
    private func didConfirmToCheckout() {
        viewModel.handleAction(.didSelectDomains(localCart.domains))
    }
}
