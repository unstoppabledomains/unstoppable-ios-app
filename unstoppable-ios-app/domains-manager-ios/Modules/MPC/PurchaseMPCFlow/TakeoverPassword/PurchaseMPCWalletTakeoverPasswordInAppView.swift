//
//  PurchaseMPCWalletTakeoverPasswordInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverPasswordInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    let email: String
    
    var body: some View {
        PurchaseMPCWalletTakeoverPasswordView(analyticsName: .mpcPurchaseTakeoverPasswordInApp,
                                              email: email,
                                              passwordCallback: didEnterTakeoverPassword)
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverPasswordInAppView {
    func didEnterTakeoverPassword(_ password: String) {
        viewModel.handleAction(.didEnterTakeoverPassword(password))
    }
}

#Preview {
    PresentAsModalPreviewView {
        PurchaseMPCWalletTakeoverPasswordInAppView(email: "qq@qq.qq")
    }
}
