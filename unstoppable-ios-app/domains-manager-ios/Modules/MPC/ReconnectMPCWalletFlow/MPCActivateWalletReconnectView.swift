//
//  MPCActivateWalletReconnectView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

struct MPCActivateWalletReconnectView: View {
    @EnvironmentObject var viewModel: ReconnectMPCWalletViewModel
    
    let credentials: MPCActivateCredentials
    let code: String
    
    var body: some View {
        MPCActivateWalletView(analyticsName: .mpcActivationInApp,
                              credentials: credentials,
                              code: code,
                              mpcWalletCreatedCallback: didCreateMPCWallet)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension MPCActivateWalletReconnectView {
    func didCreateMPCWallet(_ wallet: UDWallet) {
        viewModel.handleAction(.didActivate(wallet))
    }
    
    func didRequestToChangeEmail() {
        viewModel.handleAction(.didRequestToChangeEmail)
    }
}

#Preview {
    MPCActivateWalletReconnectView(credentials: .init(email: "",
                                                      password: ""),
                                   code: "")
}
