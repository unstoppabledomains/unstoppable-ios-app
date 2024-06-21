//
//  PurchaseMPCWalletUDAuthInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletUDAuthInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    var body: some View {
        PurchaseMPCWalletUDAuthView(analyticsName: .mpcPurchaseUDAuthInApp,
                                    credentialsCallback: didEnterCredentials)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletUDAuthInAppView {
    func didEnterCredentials(_ credentials: MPCPurchaseUDCredentials) {
        viewModel.handleAction(.didEnterPurchaseCredentials(credentials))
    }
}

#Preview {
    PurchaseMPCWalletUDAuthInAppView()
}
