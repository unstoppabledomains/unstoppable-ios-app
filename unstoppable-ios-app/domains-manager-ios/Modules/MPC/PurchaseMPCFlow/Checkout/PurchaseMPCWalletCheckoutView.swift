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
            headerView()
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
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text("Subscribe")
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func totalView() -> some View {
        switch cartStatus {
        case .ready(let cart):
            if cart.totalPrice == 0 {
                ProgressView()
                    .padding(.bottom, 6)
            } else {
                HStack {
                    Text("Total due:")
                    Spacer()
                    Text(formatCartPrice(cart.totalPrice))
                }
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
        case .ready(let cart):
            return cart.totalPrice != 0
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
                purchasedCallback()
            } catch let error as MPCWalletPurchaseError {
                didFailWithError(error)
            } catch {
                didFailWithError(.unknown)
            }
            isPurchasing = false
        }
    }
    
    func didFailWithError(_ error: MPCWalletPurchaseError) {
//        mpcStateTitle = error.title
//        activationState = .failed(error)
        switch error {
        case .walletAlreadyPurchased:
            return
//            enterDataType = .passcode
        case .unknown:
            return
        }
    }
    
}

#Preview {
    PurchaseMPCWalletCheckoutView(credentials: .init(email: "qq@qq.qq"),
                                  purchasedCallback: { })
}
