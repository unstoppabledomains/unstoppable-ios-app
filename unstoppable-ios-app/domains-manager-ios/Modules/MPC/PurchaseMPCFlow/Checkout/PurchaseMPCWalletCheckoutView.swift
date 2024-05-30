//
//  PurchaseMPCWalletCheckoutView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletCheckoutView: View, ViewAnalyticsLogger {
    
    @Environment(\.ecomPurchaseMPCWalletService) private var ecomPurchaseMPCWalletService

    let analyticsName: Analytics.ViewName
    let credentials: MPCPurchaseUDCredentials
    let purchaseStateCallback: (MPCWalletPurchasingState)->()
    let purchasedCallback: (PurchaseMPCWallet.PurchaseResult)->()
    @State private var cartStatus: PurchaseMPCWalletCartStatus = .ready(cart: .empty)
    @State private var pullUpError: PullUpErrorConfiguration?
    @State private var purchaseState = MPCWalletPurchasingState.preparing
    @State private var price: Int?

    var body: some View {
        VStack {
            headerView()
            Spacer()
            totalView()
            Spacer()
            bottomView()
        }
            .padding()
            .animation(.default, value: UUID())
            .trackAppearanceAnalytics(analyticsLogger: self)
            .onReceive(ecomPurchaseMPCWalletService.cartStatusPublisher.receive(on: DispatchQueue.main)) { cartStatus in
                if self.cartStatus.otherDiscountsApplied == 0 && cartStatus.otherDiscountsApplied != 0 {
                    appContext.toastMessageService.showToast(.purchaseDomainsDiscountApplied(cartStatus.otherDiscountsApplied), isSticky: false)
                }
                self.cartStatus = cartStatus
                checkUpdatedCartStatus()
            }
            .task {
                price = try? await EcomMPCPriceFetcher.shared.fetchPrice()
            }
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletCheckoutView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.subscribe.localized())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func totalView() -> some View {
        MPCWalletStateCardView(title: cardTitle,
                               subtitle: cardSubtitle,
                               mode: .purchase(purchaseState))
    }
    
    var cardTitle: String {
        switch purchaseState {
        case .purchasing:
            String.Constants.mpcAuthorizing.localized()
        case .preparing, .readyToPurchase, .failed:
            String.Constants.mpcProductName.localized()
        }
    }
    
    var cardSubtitle: String {
        if let price {
            return String.Constants.nPricePerYear.localized(formatCartPrice(price))
        }
        return ""
    }
    
    @ViewBuilder
    func bottomView() -> some View {
        VStack(spacing: 24) {
            errorIndicatorView()
            buyButton()
        }
    }
    
    @ViewBuilder
    func errorIndicatorView() -> some View {
        switch purchaseState {
        case .failed:
            HStack(spacing: 8) {
                Image.alertCircle
                    .resizable()
                    .squareFrame(16)
                Text(String.Constants.mpcPurchaseErrorMessage.localized())
                    .font(.currentFont(size: 14, weight: .medium))
            }
            .frame(height: 20)
            .foregroundStyle(Color.foregroundDanger)
        case .readyToPurchase, .preparing, .purchasing:
            EmptyView()
        }
    }
  
    @ViewBuilder
    func buyButton() -> some View {
        switch purchaseState {
        case .readyToPurchase, .failed:
            UDButtonView(text: String.Constants.pay.localized(),
                         icon: .appleIcon,
                         style: .large(.applePay),
                         callback: buyButtonPressed)
            .disabled(!isBuyButtonEnabled)
        case .preparing, .purchasing:
            EmptyView()
        }
    }
    
    var isBuyButtonEnabled: Bool {
        switch cartStatus {
        case .ready(let cart):
            return cart.totalPrice != 0
        default:
            switch purchaseState {
            case .failed:
                return true
            default:
                return false
            }
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
            setPurchaseState(purchaseState: .failed(.unknown))
            pullUpError = .loadCalculationsError(tryAgainCallback: callback)
        case .ready(let cart):
            if cart.totalPrice == 0 {
                return
            }
            if case .purchasing = purchaseState {
                return
            }
            setPurchaseState(purchaseState: .readyToPurchase(price: cart.totalPrice))
        }
    }
    
    func buyButtonPressed() {
        logButtonPressedAnalyticEvents(button: .buy)
        Task {
            setPurchaseState(purchaseState: .purchasing)
            do {
                try await ecomPurchaseMPCWalletService.purchaseMPCWallet()
                logAnalytic(event: .mpcWalletPurchased)
                purchasedCallback(.purchased)
            } catch let error as MPCWalletPurchaseError {
                didFailWithError(error)
            } catch {
                if let purchaseError = error as? StripeService.PurchaseError,
                   case .cancelled = purchaseError {
                    logAnalytic(event: .mpcWalletPurchaseCancelled)
                }
                didFailWithError(.unknown)
            }
        }
    }
    
    func didFailWithError(_ error: MPCWalletPurchaseError) {
        switch error {
        case .walletAlreadyPurchased:
            logAnalytic(event: .mpcWalletAlreadyPurchased)
            purchasedCallback(.alreadyHaveWallet)
        case .unknown:
            logAnalytic(event: .mpcWalletPurchaseError, parameters: [.error: error.localizedDescription])
            setPurchaseState(purchaseState: .failed(error))
        }
    }
    
    func setPurchaseState(purchaseState: MPCWalletPurchasingState) {
        self.purchaseState = purchaseState
        purchaseStateCallback(purchaseState)
    }
}

#Preview {
    PurchaseMPCWalletCheckoutView(analyticsName: .unspecified,
                                  credentials: .init(email: "qq@qq.qq"),
                                  purchaseStateCallback: { _ in },
                                  purchasedCallback: { _ in })
}
