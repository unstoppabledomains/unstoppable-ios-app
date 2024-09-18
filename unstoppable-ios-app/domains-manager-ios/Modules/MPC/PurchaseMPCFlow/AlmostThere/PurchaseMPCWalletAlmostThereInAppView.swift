//
//  PurchaseMPCWalletAlmostThereInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

struct PurchaseMPCWalletAlmostThereInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel

    var body: some View {
        PurchaseMPCWalletAlmostThereView(analyticsName: .mpcPurchaseTakeoverAlmostThereInApp,
                                              continueCallback: didTapContinue)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletAlmostThereInAppView {
    func didTapContinue() {
        viewModel.handleAction(.didTapContinueAfterTakeover)
    }
}

#Preview {
    PresentAsModalPreviewView {
        PurchaseMPCWalletAlmostThereInAppView()
    }
}
