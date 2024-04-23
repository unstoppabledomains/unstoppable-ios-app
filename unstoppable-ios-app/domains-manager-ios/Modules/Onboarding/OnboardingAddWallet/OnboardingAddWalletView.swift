//
//  OnboardingAddWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import SwiftUI

struct OnboardingAddWalletView: View {
    
    let options: [[OnboardingAddWalletType]]
    let selectionCallback: (OnboardingAddWalletType)->()
    
    var body: some View {
        OnboardingStartOptionsView(title: String.Constants.createNewVaultTitle.localized(),
                                   subtitle: String.Constants.createNewVaultSubtitle.localized(),
                                   icon: .plusCircle,
                                   options: options,
                                   selectionCallback: selectionCallback)
        .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingAddWalletView(options: [],
                            selectionCallback:  { _ in })
}
