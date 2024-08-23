//
//  PurchaseMPCWalletTakeoverCredentialsInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverCredentialsInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel

    let purchaseEmail: String?
    
    var body: some View {
        PurchaseMPCWalletTakeoverCredentialsView(analyticsName: .mpcPurchaseTakeoverCredentialsInApp,
                                                 purchaseEmail: purchaseEmail, credentialsCallback: didEnterTakeoverCredentials)
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverCredentialsInAppView {
    func didEnterTakeoverCredentials(_ credentials: MPCActivateCredentials) {
        viewModel.handleAction(.didEnterTakeoverCredentials(credentials))
    }
}

#Preview {
    PresentAsModalPreviewView {
        PurchaseMPCWalletTakeoverCredentialsInAppView(purchaseEmail: "qq@qq.qq")
    }
}
