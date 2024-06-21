//
//  MPCActivateWalletInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

struct MPCActivateWalletInAppView: View {
    
    @EnvironmentObject var viewModel: ActivateMPCWalletViewModel

    let credentials: MPCActivateCredentials
    let code: String
    
    var body: some View {
        MPCActivateWalletView(analyticsName: .mpcActivationInApp, 
                              credentials: credentials,
                              code: code,
                              mpcWalletCreatedCallback: didCreateMPCWallet,
                              changeEmailCallback: didRequestToChangeEmail)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension MPCActivateWalletInAppView {
    func didCreateMPCWallet(_ wallet: UDWallet) {
        viewModel.handleAction(.didActivate(wallet))
    }
    
    func didRequestToChangeEmail() {
        viewModel.handleAction(.didRequestToChangeEmail)
    }
}

#Preview {
    MPCActivateWalletInAppView(credentials: .init(email: "",
                                                  password: ""),
                               code: "")
}
