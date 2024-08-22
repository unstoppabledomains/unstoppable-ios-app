//
//  ConfirmTakeoverEmailView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import SwiftUI

struct ConfirmTakeoverEmailInAppView: View {
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    let email: String
    
    var body: some View {
        MPCEnterCodeView(analyticsName: .mpcEnterCodeInApp,
                         email: email,
                         enterCodeCallback: didEnterCode)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension ConfirmTakeoverEmailInAppView {
    func didEnterCode(_ code: String) {
        viewModel.handleAction(.didConfirmTakeoverEmail(code: code))
    }
}

#Preview {
    ConfirmTakeoverEmailInAppView(email: "qq@qq.qq")
}
