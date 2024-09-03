//
//  PurchaseMPCWalletAlmostThereView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

struct PurchaseMPCWalletAlmostThereView: View, ViewAnalyticsLogger {
    
    let analyticsName: Analytics.ViewName
    let continueCallback: EmptyCallback
    
    var body: some View {
        ZStack {
            contentView()
            continueButton()
        }
        .padding()
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletAlmostThereView {
    @ViewBuilder
    func contentView() -> some View {
        VStack(spacing: 24) {
            Image.checkCircle
                .resizable()
                .squareFrame(56)
                .foregroundStyle(Color.foregroundAccent)
            VStack(spacing: 16) {
                Text(String.Constants.mpcTakeoverAlmostThereTitle.localized())
                    .titleText()
                Text(String.Constants.mpcTakeoverAlmostThereSubtitle.localized())
                    .subtitleText()
            }
            .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func continueButton() -> some View {
        VStack {
            Spacer()
            UDButtonView(text: String.Constants.continue.localized(),
                         style: .large(.raisedPrimary),
                         callback: actionButtonPressed)
        }
    }
    
    func actionButtonPressed() {
        logButtonPressedAnalyticEvents(button: .continue)
        continueCallback()
    }
}

#Preview {
    PurchaseMPCWalletAlmostThereView(analyticsName: .addEmail,
                                     continueCallback: { })
}
