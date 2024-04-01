//
//  ConfirmSendTokenView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    
    @ObservedObject private var dataModel: ConfirmSendTokenDataModel
    @State private var error: Error?
    @State private var isLoading = false
    @State private var stateId = UUID()
    @State private var lastRefreshGasFeeTime = Date()
    @State private var lastRefreshGasPricesTime = Date()
    private var token: BalanceTokenUIDescription { dataModel.token }
    private var receiver: SendCryptoAsset.AssetReceiver { dataModel.receiver }
    private let refreshGasTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var analyticsName: Analytics.ViewName { .sendCryptoTokenConfirmation }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.token: token.id,
                                                                         .value: String(dataModel.amount.valueOf(type: .tokenAmount,
                                                                                                          for: token)),
                                                                         .toWallet: dataModel.receiver.walletAddress,
                                                                         .fromWallet: viewModel.sourceWallet.address] }
    
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
            refreshGasFeeForSelectedSpeed()
        }
        .onReceive(refreshGasTimer) { _ in
            refreshGasFeeForSelectedSpeedIfNeeded()
            refreshGasPricesIfNeeded()
        }
        .padding(16)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .trackAppearanceAnalytics(analyticsLogger: self)
        .passViewAnalyticsDetails(logger: self)
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
        refreshGasFeeForSelectedSpeed()
        refreshGasPrices()
    }
    
    func refreshGasFeeForSelectedSpeed() {
        lastRefreshGasFeeTime = Date()
        dataModel.gasFee = nil
        updateStateId()
        Task {
            isLoading = true
            do {
                dataModel.gasFee = try await viewModel.computeGasFeeFor(sendData: dataModel.data,
                                                                        txSpeed: dataModel.txSpeed)
                updateStateId()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func refreshGasFeeForSelectedSpeedIfNeeded() {
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshGasFeeTime)
        if timeSinceLastRefresh >= 60 {
            refreshGasFeeForSelectedSpeed()
        }
    }
    
    func refreshGasPrices() {
        lastRefreshGasPricesTime = Date()
        Task {
            do {
                dataModel.gasPrices = try await viewModel.getGasPrices(sendData: dataModel.data)
                updateStateId()
            } catch { }
        }
    }
    
    func refreshGasPricesIfNeeded() {
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshGasPricesTime)
        if timeSinceLastRefresh >= 60 {
            refreshGasPrices()
        }
    }
    
    func updateStateId() {
        stateId = UUID()
    }
    
    func confirmSending() {
        logButtonPressedAnalyticEvents(button: .confirm,
                                       parameters: [.transactionSpeed: dataModel.txSpeed.rawValue])

        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }
            try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)

            isLoading = true
            do {
                let txHash = try await viewModel.sendCryptoTokenWith(sendData: dataModel.data,
                                                                     txSpeed: dataModel.txSpeed)
                logAnalytic(event: .didSendCrypto,
                            parameters: [.transactionSpeed: dataModel.txSpeed.rawValue])
                viewModel.handleAction(.didSendCrypto(data: dataModel.data, txHash: txHash))
            } catch {
                logAnalytic(event: .didFailToSendCrypto,
                            parameters: [.transactionSpeed: dataModel.txSpeed.rawValue,
                                         .error: error.localizedDescription])
                self.error = error
            }
            isLoading = false
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
    
    var isSufficientFunds: Bool {
        guard let gasFee = dataModel.gasFee else { return true }
        
        let sendData = dataModel.data
        let balance = sendData.token.balance
        if sendData.isSendingAllTokens() {
            return balance >= gasFee
        }
        
        let tokenAmountToSend = sendData.getTokenAmountValueToSend()
        return balance > tokenAmountToSend + gasFee
    }
    
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
