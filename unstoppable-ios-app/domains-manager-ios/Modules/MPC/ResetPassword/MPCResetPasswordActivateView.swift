//
//  MPCResetPasswordActivateView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2024.
//

import SwiftUI

struct MPCResetPasswordActivateView: View {
    @EnvironmentObject var viewModel: MPCResetPasswordViewModel
    
    let data: MPCResetPasswordFlow.ResetPasswordFullData
    
    var body: some View {
        MPCActivateWalletView(analyticsName: .mpcActivationRestorePassword,
                              flow: .resetPassword(data.resetPasswordData,
                                                   newPassword: data.newPassword),
                              code: data.code,
                              mpcWalletCreatedCallback: didCreateMPCWallet)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension MPCResetPasswordActivateView {
    func didCreateMPCWallet(_ wallet: UDWallet) {
        viewModel.handleAction(.didActivate(wallet))
    }
}

#Preview {
    MPCResetPasswordActivateView(data: .init(resetPasswordData: .init(email: "",
                                                                      recoveryToken: ""),
                                             newPassword: "",
                                             code: ""))
}
