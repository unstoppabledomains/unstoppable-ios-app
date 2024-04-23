//
//  RestoreWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import SwiftUI

struct RestoreWalletView: View {
    
    let options: [[OnboardingStartOption]]
    let selectionCallback: (OnboardingStartOption)->()

    var body: some View {
        OnboardingStartOptionsView(title: String.Constants.connectWalletTitle.localized(),
                                   subtitle: String.Constants.connectWalletSubtitle.localized(),
                                   icon: .addWalletIcon,
                                   options: options,
                                   selectionCallback: selectionCallback)
        .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
        .ignoresSafeArea()
    }
}

#Preview {
    RestoreWalletView(options: [[]],
                      selectionCallback: { _ in })
}
