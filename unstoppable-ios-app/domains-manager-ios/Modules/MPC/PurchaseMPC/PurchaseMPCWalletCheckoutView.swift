//
//  PurchaseMPCWalletCheckoutView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletCheckoutView: View {
    
    @Environment(\.ecomPurchaseMPCWalletService) private var ecomPurchaseMPCWalletService

    @State private var cartStatus: PurchaseMPCWalletCartStatus = .ready(cart: .empty)
    @State private var pullUpError: PullUpErrorConfiguration?

    var body: some View {
        Text("Ji")
            .background(Color.backgroundDefault)
            .animation(.default, value: UUID())
            .onReceive(ecomPurchaseMPCWalletService.cartStatusPublisher.receive(on: DispatchQueue.main)) { cartStatus in
                if self.cartStatus.otherDiscountsApplied == 0 && cartStatus.otherDiscountsApplied != 0 {
                    appContext.toastMessageService.showToast(.purchaseDomainsDiscountApplied(cartStatus.otherDiscountsApplied), isSticky: false)
                }
                self.cartStatus = cartStatus
                checkUpdatedCartStatus()
            }
    }
    
    
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletCheckoutView {
    func checkUpdatedCartStatus() {
        switch cartStatus {
        case .alreadyPurchasedMPCWallet:
            // TODO: - Show on the UI
            return
        case .failedToLoadCalculations(let callback):
            pullUpError = .loadCalculationsError(tryAgainCallback: callback)
        default:
            return
        }
    }
}

#Preview {
    PurchaseMPCWalletCheckoutView()
}
