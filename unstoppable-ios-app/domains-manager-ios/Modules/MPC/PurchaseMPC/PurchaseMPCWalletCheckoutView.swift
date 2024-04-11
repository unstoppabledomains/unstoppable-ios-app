//
//  PurchaseMPCWalletCheckoutView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletCheckoutView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    @Environment(\.ecomPurchaseMPCWalletService) private var ecomPurchaseMPCWalletService

    @State private var cartStatus: PurchaseMPCWalletCartStatus = .ready(cart: .empty)
    @State private var pullUpError: PullUpErrorConfiguration?
    @State private var isPurchasing = false

    var body: some View {
        VStack {
            Spacer()
            totalView()
            buyButton()
            Spacer()
        }
            .padding()
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
    @ViewBuilder
    func totalView() -> some View {
        if case .ready(let cart) = cartStatus {
            HStack {
                Text("Total due:")
                Spacer()
                Text(formatCartPrice(cart.totalPrice))
            }
        } else {
            Text("Loading...")
        }
    }
    
    @ViewBuilder
    func buyButton() -> some View {
        UDButtonView(text: String.Constants.pay.localized(),
                     style: .large(.applePay),
                     isLoading: isPurchasing,
                     callback: confirmPurchase)
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
    
    func confirmPurchase() {
        Task {
            isPurchasing = true
            do {
                try await ecomPurchaseMPCWalletService.purchaseMPCWallet()
                viewModel.handleAction(.didPurchase)
            } catch {
                
            }
            isPurchasing = false
        }
    }
}

#Preview {
    PurchaseMPCWalletCheckoutView()
        .environmentObject(PurchaseMPCWalletViewModel())
}
