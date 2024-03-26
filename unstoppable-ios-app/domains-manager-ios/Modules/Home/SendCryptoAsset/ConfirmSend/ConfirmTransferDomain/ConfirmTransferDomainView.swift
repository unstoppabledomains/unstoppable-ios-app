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
    @State private var pullUp: ViewPullUpConfigurationType?
    @State private var isLoading: Bool = false
    @State private var error: Error?

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
        .viewPullUp($pullUp)
        .displayError($error)
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
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: continueButtonPressed)
    }
    
    func continueButtonPressed() {
        pullUp = .custom(.transferDomainConfirmationPullUp(confirmCallback: transferConfirmed))
    }
    
    func transferConfirmed(_ confirmationData: SendCryptoAsset.TransferDomainConfirmationData) {
        pullUp = nil
        Task {
            isLoading = true
            await Task.sleep(seconds: 0.35)
            
            do {
                let domain = self.data.domain
                let recipientAddress = self.data.receiver.walletAddress
                let configuration = TransferDomainConfiguration(resetRecords: confirmationData.shouldClearRecords)
                try await appContext.domainTransferService.transferDomain(domain: domain.toDomainItem(),
                                                                          to: recipientAddress,
                                                                          configuration: configuration)
                appContext.analyticsService.log(event: .didTransferDomain,
                                                withParameters: [.domainName: domain.name,
                                                                 .fromWallet: domain.ownerWallet ?? "",
                                                                 .toWallet: recipientAddress])
                Task.detached {
                    try? await appContext.walletsDataService.refreshDataForWallet(viewModel.sourceWallet)
                }
                
                viewModel.handleAction(.didTransferDomain(domain))
            } catch {
                self.error = error
            }
            
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        ConfirmTransferDomainView(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                              domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo()))
    }
    .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
