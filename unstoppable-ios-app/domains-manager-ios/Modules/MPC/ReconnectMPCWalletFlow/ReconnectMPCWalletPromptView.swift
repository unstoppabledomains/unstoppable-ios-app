//
//  ReconnectMPCWalletPromptView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

struct ReconnectMPCWalletPromptView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: ReconnectMPCWalletViewModel

    let walletAddress: String
    var analyticsName: Analytics.ViewName { .reconnectMPCWalletPrompt }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.wallet : walletAddress] }
    @State private var pullUp: ViewPullUpConfigurationType?

    var body: some View {
        VStack {
            headerView()
            Spacer()
            actionButtons()
        }
        .padding()
        .background(Color.backgroundDefault)
        .trackAppearanceAnalytics(analyticsLogger: self)
        .viewPullUp($pullUp)
    }
}

// MARK: - Private methods
private extension ReconnectMPCWalletPromptView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 20) {
            headerIcon()
            VStack(spacing: 16) {
                titleText()
                subtitleText()
            }
        }
        .padding(.top, 40)
    }
    
    @ViewBuilder
    func headerIcon() -> some View {
        Image.shieldKeyhole
            .resizable()
            .foregroundStyle(Color.white)
            .squareFrame(48)
            .padding(16)
            .background(Color.backgroundAccentEmphasis)
            .clipShape(Circle())
    }
    
    var walletAddressInBrackets: String {
        "(\(walletAddress.walletAddressTruncated))"
    }
    
    @ViewBuilder
    func titleText() -> some View {
        AttributedText(attributesList: .init(text: String.Constants.reImportMPCWalletPromptTitle.localized(walletAddressInBrackets), font: .currentFont(withSize: 32, weight: .bold), textColor: .foregroundDefault, alignment: .center),
                       updatedAttributesList: [.init(text: walletAddressInBrackets, textColor: .foregroundSecondary)],
                       flexibleHeight: false)
            
    }
    
    @ViewBuilder
    func subtitleText() -> some View {
        Text(String.Constants.reImportMPCWalletPromptSubtitle.localizedMPCProduct())
            .textAttributes(color: .foregroundSecondary, fontSize: 16)
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func actionButtons() -> some View {
        VStack(spacing: 16) {
            reconnectButton()
            removeButton()
        }
    }
    
    @ViewBuilder
    func reconnectButton() -> some View {
        UDButtonView(text: String.Constants.reImportWallet.localized(),
                     style: .large(.raisedPrimary),
                     callback: reconnectButtonPressed)
    }
    
    func reconnectButtonPressed() {
        logButtonPressedAnalyticEvents(button: .walletReconnect)
        viewModel.handleAction(.reImportWallet)
    }
    
    @ViewBuilder
    func removeButton() -> some View {
        UDButtonView(text: String.Constants.removeWallet.localized(),
                     style: .large(.ghostPrimary),
                     callback: removeButtonPressed)
    }
    
    func removeButtonPressed() {
        logButtonPressedAnalyticEvents(button: .walletRemove)
        pullUp = .default(.askToReconnectMPCWalletPullUp(walletAddress: walletAddressInBrackets, removeCallback: removeWalletConfirmed))
    }
    
    func removeWalletConfirmed() {
        viewModel.handleAction(.removeWallet)
    }
}

#Preview {
    NavigationStack {
        ReconnectMPCWalletPromptView(walletAddress: MockEntitiesFabric.Wallet.mockEntities()[0].address)
    }
}
