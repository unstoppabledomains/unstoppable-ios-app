//
//  ConfirmTransferDomainView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct ConfirmTransferDomainView: View {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel

    let data: SendCryptoAsset.TransferDomainData

    var body: some View {
        VStack(spacing: 4) {
            sendingTokenInfoView()
            senderReceiverConnectorView()
            receiverInfoView()
            reviewInfoView()
            Spacer()
            continueButton()
        }
        .padding(16)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .addNavigationTopSafeAreaOffset()
        .navigationTitle(String.Constants.youAreSending.localized())
    }
}

// MARK: - Private methods
private extension ConfirmTransferDomainView {
    @ViewBuilder
    func sendingTokenInfoView() -> some View {
        ConfirmSendAssetSendingInfoView(asset: .domain(data.domain))
    }
    
    @ViewBuilder
    func receiverInfoView() -> some View {
        ConfirmSendAssetReceiverInfoView(receiver: data.receiver)
    }
    
    @ViewBuilder
    func senderReceiverConnectorView() -> some View {
        ConfirmSendAssetSenderReceiverConnectView()
    }
    
    @ViewBuilder
    func reviewInfoView() -> some View {
        ConfirmSendAssetReviewInfoView(asset: .domain(data.domain),
                                       sourceWallet: viewModel.sourceWallet)
    }
    
    @ViewBuilder
    func continueButton() -> some View {
        UDButtonView(text: String.Constants.continue.localized(),
                     icon: confirmIcon,
                     style: .large(.raisedPrimary)) {
            
        }
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
        ConfirmTransferDomainView(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                              domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo()))
    }
    .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
