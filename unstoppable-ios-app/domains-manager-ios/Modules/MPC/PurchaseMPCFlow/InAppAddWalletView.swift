//
//  InAppAddWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct InAppAddWalletView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    var body: some View {
        OnboardingStartOptionsView(title: String.Constants.createNewVaultTitle.localized(),
                                   subtitle: String.Constants.createNewVaultSubtitle.localized(),
                                   icon: .plusCircle,
                                   options: [[.mpcWallet], [.selfCustody]],
                                   selectionCallback: didSelectAddWalletType)
        .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
        .ignoresSafeArea()
    }
    
}

// MARK: - Private methods
private extension InAppAddWalletView {
    func didSelectAddWalletType(_ type: OnboardingAddWalletType) {
        switch type {
        case .mpcWallet:
            viewModel.handleAction(.buyMPCWallet)
        case .selfCustody:
            viewModel.handleAction(.createNewWallet)
        }
    }
}

#Preview {
    InAppAddWalletView()
}
