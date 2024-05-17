//
//  PurchaseMPCWalletCheckoutView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletCheckoutView: View {
    
    @Environment(\.ecomPurchaseMPCWalletService) private var ecomPurchaseMPCWalletService

    let credentials: MPCPurchaseUDCredentials
    let purchasedCallback: EmptyCallback
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
        switch cartStatus {
        case .ready(let cart):
            HStack {
                Text("Total due:")
                Spacer()
                Text(formatCartPrice(cart.totalPrice))
            }
        case .alreadyPurchasedMPCWallet:
            Text("User already own mpc wallet")
                .foregroundStyle(Color.foregroundSuccess)
        case .failedToLoadCalculations:
            Text("Failed to load cart details")
        }
    }
    
    var isBuyButtonEnabled: Bool {
        switch cartStatus {
        case .ready:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    func buyButton() -> some View {
        UDButtonView(text: String.Constants.pay.localized(),
                     style: .large(.applePay),
                     isLoading: isPurchasing,
                     callback: confirmPurchase)
        .disabled(!isBuyButtonEnabled)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletCheckoutView {
    func checkUpdatedCartStatus() {
        switch cartStatus {
        case .alreadyPurchasedMPCWallet:
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
//                viewModel.handleAction(.didPurchase)
                // Just close the flow for now
            } catch {
                
            }
            isPurchasing = false
        }
    }
}

#Preview {
    PurchaseMPCWalletCheckoutView(credentials: .init(email: "qq@qq.qq"),
                                  purchasedCallback: { })
}
