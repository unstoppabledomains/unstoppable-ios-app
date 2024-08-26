//
//  PurchaseMPCWalletTakeoverCredentialsInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverEmailInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    var body: some View {
        PurchaseMPCWalletTakeoverEmailView(analyticsName: .mpcPurchaseTakeoverCredentialsInApp, emailCallback: didEnterTakeoverEmail)
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverEmailInAppView {
    func didEnterTakeoverEmail(_ email: String) {
        viewModel.handleAction(.didEnterTakeoverEmail(email))
    }
}

#Preview {
    PresentAsModalPreviewView {
        PurchaseMPCWalletTakeoverEmailInAppView()
    }
}
