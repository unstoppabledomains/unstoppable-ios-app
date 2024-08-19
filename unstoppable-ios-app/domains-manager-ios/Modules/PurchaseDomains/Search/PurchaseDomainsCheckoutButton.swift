//
//  PurchaseDomainsCheckoutButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2024.
//

import SwiftUI

struct PurchaseDomainsCheckoutButton: ViewModifier, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel
    
    func body(content: Content) -> some View {
        VStack {
            content
            
            if !viewModel.localCart.domains.isEmpty {
                UDButtonView(text: String.Constants.checkout.localized(),
                             subtext: subtitle,
                             style: .large(.raisedPrimary)) {
                    logButtonPressedAnalyticEvents(button: .checkout)
                    if viewModel.localCart.isShowingCart {
                        viewModel.localCart.isShowingCart = false
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
        "\(String.Constants.totalDue.localized()): \(formatCartPrice(viewModel.localCart.totalPrice))"
    }
    
    private func didConfirmToCheckout() {
        viewModel.handleAction(.didSelectDomains(viewModel.localCart.domains))
    }
}
