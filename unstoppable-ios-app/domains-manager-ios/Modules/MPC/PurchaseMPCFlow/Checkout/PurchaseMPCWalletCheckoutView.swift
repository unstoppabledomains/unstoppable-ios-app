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
    @State private var purchaseState = MPCWalletPurchasingState.preparing

    var body: some View {
        VStack {
            headerView()
            Spacer()
            totalView()
            Spacer()
            buyButton()
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
        MPCActivateWalletStateCardView(title: cardTitle,
                                       mode: .activation(.activating),
                                       mpcCreateProgress: 0)
    }
    
    var cardTitle: String {
        switch purchaseState {
        case .purchasing:
            "Authorizing"
        case .preparing, .readyToPurchase:
            String.Constants.mpcProductName.localized()
        case .failed:
            String.Constants.somethingWentWrong.localized()
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
        switch purchaseState {
        case .readyToPurchase, .failed:
            UDButtonView(text: String.Constants.pay.localized(),
                         style: .large(.applePay),
                         callback: confirmPurchase)
            .disabled(!isBuyButtonEnabled)
        case .preparing, .purchasing:
            EmptyView()
        }
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletCheckoutView {
    func checkUpdatedCartStatus() {
        switch cartStatus {
        case .alreadyPurchasedMPCWallet:
            return
        case .failedToLoadCalculations(let callback):
            purchaseState = .failed(.unknown)
            pullUpError = .loadCalculationsError(tryAgainCallback: callback)
        case .ready(let cart):
            if case .purchasing = purchaseState {
                return
            }
            purchaseState = .readyToPurchase(price: cart.totalPrice)
        }
    }
    
    func confirmPurchase() {
        Task {
            purchaseState = .purchasing
            do {
                try await ecomPurchaseMPCWalletService.purchaseMPCWallet()
                purchasedCallback()
            } catch let error as MPCWalletPurchaseError {
                didFailWithError(error)
            } catch {
                didFailWithError(.unknown)
            }
        }
    }
    
    func didFailWithError(_ error: MPCWalletPurchaseError) {
//        mpcStateTitle = error.title
        purchaseState = .failed(error)
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
