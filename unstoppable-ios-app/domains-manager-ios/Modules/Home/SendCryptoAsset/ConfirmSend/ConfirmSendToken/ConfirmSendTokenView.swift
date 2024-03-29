//
//  ConfirmSendTokenView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenView: View {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    
    @ObservedObject private var dataModel: ConfirmSendTokenDataModel
    @State private var error: Error?
    @State private var isLoading = false
    @State private var stateId = UUID()
    @State private var lastRefreshGasTime = Date()
    private var token: BalanceTokenUIDescription { dataModel.token }
    private var receiver: SendCryptoAsset.AssetReceiver { dataModel.receiver }
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {
            sendingTokenInfoView()
            senderReceiverConnectorView()
            receiverInfoView()
            reviewInfoView()
            Spacer()
            confirmButton()
        }
        .onChange(of: dataModel.txSpeed) { _ in
            refreshGasAmount()
        }
        .onReceive(timer) { _ in
            refreshGasIfNeeded()
        }
        .padding(16)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .addNavigationTopSafeAreaOffset()
        .navigationTitle(String.Constants.youAreSending.localized())
        .displayError($error)
        .onAppear(perform: onAppear)
    }
    
    init(data: SendCryptoAsset.SendTokenAssetData) {
        self.dataModel = ConfirmSendTokenDataModel(data: data)
    }
    
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    func onAppear() {
        refreshGasAmount()
    }
    
    func refreshGasAmount() {
        lastRefreshGasTime = Date()
        dataModel.gasAmount = nil
        updateStateId()
        Task {
            isLoading = true
            do {
                dataModel.gasAmount = try await viewModel.computeGasFeeFor(sendData: dataModel.data,
                                                                           txSpeed: dataModel.txSpeed)
                updateStateId()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func confirmSending() {
        Task {
            isLoading = true
            do {
//                try await viewModel.sendToken(data: dataModel.data)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func updateStateId() {
        stateId = UUID()
    }
    
    func refreshGasIfNeeded() {
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshGasTime)
        if timeSinceLastRefresh >= 60 {
            refreshGasAmount()
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    @ViewBuilder
    func sendingTokenInfoView() -> some View {
        ConfirmSendAssetSendingInfoView(asset: .token(token: token,
                                                      amount: dataModel.amount))
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
        ConfirmSendAssetReviewInfoView(asset: .token(dataModel),
                                       sourceWallet: viewModel.sourceWallet)
        .id(stateId)
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
                         style: .large(.raisedPrimary),
                         isLoading: isLoading) {
                confirmSending()
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
