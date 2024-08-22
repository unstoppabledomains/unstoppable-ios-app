//
//  MPCActivateWalletInAppAfterClaimView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import SwiftUI

struct MPCActivateWalletInAppAfterClaimView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    let credentials: MPCActivateCredentials
    let code: String
    
    var body: some View {
        MPCActivateWalletView(analyticsName: .mpcActivationInApp,
                              credentials: credentials,
                              code: code,
                              mpcWalletCreatedCallback: didCreateMPCWallet,
                              changeEmailCallback: nil)
    }
}

// MARK: - Private methods
private extension MPCActivateWalletInAppAfterClaimView {
    func didCreateMPCWallet(_ wallet: UDWallet) {
        viewModel.handleAction(.didActivate(wallet))
    }
}

#Preview {
    MPCActivateWalletInAppAfterClaimView(credentials: .init(email: "",
                                                  password: ""),
                                         code: "")
}
