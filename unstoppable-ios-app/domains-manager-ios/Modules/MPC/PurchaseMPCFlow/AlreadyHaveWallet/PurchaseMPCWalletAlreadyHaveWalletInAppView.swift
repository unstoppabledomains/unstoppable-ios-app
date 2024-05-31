//
//  PurchaseMPCWalletAlreadyHaveWalletInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletAlreadyHaveWalletInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    let email: String
    
    var body: some View {
        PurchaseMPCWalletAlreadyHaveWalletView(analyticsName: .mpcPurchaseAlreadyHaveWalletInApp,
                                               email: email,
                                               callback: didSelectAction)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletAlreadyHaveWalletInAppView {
    func didSelectAction(_ action: PurchaseMPCWallet.AlreadyHaveWalletAction) {
        viewModel.handleAction(.didSelectAlreadyHaveWalletAction(action))
    }
}

#Preview {
    PresentAsModalPreviewView {
        PurchaseMPCWalletAlreadyHaveWalletInAppView(email: "qq@qq.qq")
    }
}
