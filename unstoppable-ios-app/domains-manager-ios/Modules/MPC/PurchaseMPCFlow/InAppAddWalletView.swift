//
//  InAppAddWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct InAppAddWalletView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    var analyticsName: Analytics.ViewName { .inAppAddWallet }
    
    var body: some View {
        OnboardingStartOptionsView(title: String.Constants.createNewVaultTitle.localized(),
                                   subtitle: String.Constants.createNewVaultSubtitle.localized(),
                                   icon: .plusCircle,
                                   options: [[.mpcWallet], [.selfCustody]],
                                   selectionCallback: didSelectAddWalletType)
        .trackAppearanceAnalytics(analyticsLogger: self)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseButtonView {
                    viewModel.navigationState?.dismiss = true
                }
            }
        }
    }
    
}

// MARK: - Private methods
private extension InAppAddWalletView {
    func didSelectAddWalletType(_ type: OnboardingAddWalletType) {
        switch type {
        case .mpcWallet:
            viewModel.handleAction(.createMPCWallet)
        case .selfCustody:
            viewModel.handleAction(.createNewWallet)
        }
    }
}

#Preview {
    InAppAddWalletView()
}
