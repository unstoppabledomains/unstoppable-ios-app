//
//  ConfirmSendTokenView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenView: View {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel

    let data: SendCryptoAsset.SendTokenAssetData
    
    private var token: BalanceTokenUIDescription { data.token }
    private var receiver: SendCryptoAsset.AssetReceiver { data.receiver }
    
    var body: some View {
        VStack(spacing: 4) {
            sendingTokenInfoView()
            senderReceiverConnectorView()
            receiverInfoView()
            reviewInfoView()
            Spacer()
            confirmButton()
        }
        .padding(16)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .addNavigationTopSafeAreaOffset()
        .navigationTitle(String.Constants.youAreSending.localized())
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    @ViewBuilder
    func sendingTokenInfoView() -> some View {
        ConfirmSendAssetSendingInfoView(asset: .token(token: token,
                                                      amount: data.amount))
    }
    
    @ViewBuilder
    func receiverInfoView() -> some View {
        ConfirmSendAssetReceiverInfoView(receiver: receiver)
    }
    
    @ViewBuilder
    func senderReceiverConnectorView() -> some View {
        ConfirmSendAssetSenderReceiverConnectView()
    }
    
    @ViewBuilder
    func reviewInfoView() -> some View {
        ConfirmSendAssetReviewInfoView(asset: .token(token),
                                       sourceWallet: viewModel.sourceWallet)
    }
    
    var isSufficientFunds: Bool { true }
    
    @ViewBuilder
    func confirmButton() -> some View {
        VStack(spacing: isIPSE ? 6 : 24) {
            if !isSufficientFunds {
                insufficientFundsLabel()
            }
            UDButtonView(text: String.Constants.confirm.localized(),
                         icon: confirmIcon,
                         style: .large(.raisedPrimary)) {
                
            }
                         .disabled(!isSufficientFunds)
        }
    }
    
    @ViewBuilder
    func insufficientFundsLabel() -> some View {
        HStack(spacing: 8) {
            Image.infoIcon
                .resizable()
                .squareFrame(16)
            Text(String.Constants.notEnoughToken.localized(token.symbol))
                .font(.currentFont(size: 14, weight: .medium))
        }
        .foregroundStyle(Color.foregroundDanger)
        .frame(height: 20)
    }
    
    var confirmIcon: Image? {
        if User.instance.getSettings().touchIdActivated,
           let icon = appContext.authentificationService.biometricIcon {
            return Image(uiImage: icon)
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        ConfirmSendTokenView(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                         token: MockEntitiesFabric.Tokens.mockUIToken(),
                                         amount: .usdAmount(3998234.3)))
            .navigationBarTitleDisplayMode(.inline)
    }
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
