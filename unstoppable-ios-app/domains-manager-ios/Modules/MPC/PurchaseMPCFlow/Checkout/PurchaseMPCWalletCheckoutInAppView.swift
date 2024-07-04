//
//  PurchaseMPCWalletCheckoutInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletCheckoutInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel

    let credentials: MPCPurchaseUDCredentials
    @State private var purchasingState = MPCWalletPurchasingState.preparing
    
    var body: some View {
        PurchaseMPCWalletCheckoutView(analyticsName: .mpcPurchaseCheckoutInApp,
                                      credentials: credentials,
                                      purchaseStateCallback: handlePurchasingStateUpdated,
                                      purchasedCallback: handleWalletPurchaseResult)
        .navigationBarBackButtonHidden(!purchasingState.isAllowedToInterrupt)
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletCheckoutInAppView {
    func handlePurchasingStateUpdated(_ purchasingState: MPCWalletPurchasingState) {
        self.purchasingState = purchasingState
    }
    
    func handleWalletPurchaseResult(_ result: PurchaseMPCWallet.PurchaseResult) {
        viewModel.handleAction(.didPurchase(result))
    }
}

#Preview {
    PurchaseMPCWalletCheckoutInAppView(credentials: .init(email: "qq@qq.qq"))
}
