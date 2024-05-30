//
//  PurchaseMPCWalletTakeoverRecoveryInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverRecoveryInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    let email: String
    
    var body: some View {
        PurchaseMPCWalletTakeoverRecoveryView(analyticsName: .mpcPurchaseTakeoverRecoveryInApp,
                                              email: email,
                                              confirmCallback: didSelectToSendRecoveryLink)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
        .navigationBarBackButtonHidden(false)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverRecoveryInAppView {
    func didSelectToSendRecoveryLink(_ sendRecoveryLink: Bool) {
        viewModel.handleAction(.didSelectTakeoverRecoveryTo(sendRecoveryLink: sendRecoveryLink))
    }
}

#Preview {
    PurchaseMPCWalletTakeoverRecoveryInAppView(email: "qq@qq.qq")
}
