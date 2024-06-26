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
    @State private var pullUp: ViewPullUpConfigurationType?
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
                                                                         .toWallet: dataModel.data.receiverAddress,
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
        .viewPullUp($pullUp)
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
    
    func confirmButtonPressed() {
        if UserDefaults.isSendingCryptoForTheFirstTime {
            pullUp = .default(.showSendCryptoForTheFirstTimeConfirmationPullUp(confirmCallback: {
                Task {
                    await Task.sleep(seconds: 0.4)
                    confirmSending()
                }
            }))
        } else {
            confirmSending()
        }
    }
    
    func confirmSending() {
        UserDefaults.isSendingCryptoForTheFirstTime = false
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
        ConfirmSendAssetReceiverInfoView(receiver: receiver,
                                         receiverAddress: dataModel.data.receiverAddress,
                                         chainType: token.blockchainType ?? .Matic)
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
    
    var hasSufficientFunds: Bool {
        guard let gasFee = dataModel.gasFee else { return true }
        
        let sendData = dataModel.data
        let token = sendData.token
        
        if let parent = token.parent { // ERC20 Token
            let parentBalance = parent.balance
            return parentBalance >= gasFee
        } else {
            let balance = token.balance
            if sendData.isSendingAllTokens() {
                return balance >= gasFee
            }
            
            let tokenAmountToSend = sendData.getTokenAmountValueToSend()
            return balance > tokenAmountToSend + gasFee
        }
    }
    
    @ViewBuilder
    func confirmButton() -> some View {
        VStack(spacing: isIPSE ? 6 : 16) {
            if !hasSufficientFunds,
               !dataModel.token.isERC20Token {
                insufficientFundsLabel()
            } else {
                totalValueLabel()
            }
            UDButtonView(text: String.Constants.confirm.localized(),
                         icon: confirmIcon,
                         style: .large(.raisedPrimary),
                         isLoading: isLoading) {
                logButtonPressedAnalyticEvents(button: .confirm,
                                               parameters: [.transactionSpeed: dataModel.txSpeed.rawValue])
                confirmButtonPressed()
            }
                         .disabled(!hasSufficientFunds)
        }
        .padding(.bottom, safeAreaInset.bottom)
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
        
    func totalValue(gasFee: Double) -> Double {
        let sendData = dataModel.data
        var amountToSpend = sendData.amount.valueOf(type: .tokenAmount, for: token)
        if !sendData.isSendingAllTokens(),
           !token.isERC20Token {
            amountToSpend += gasFee
        }
        return amountToSpend
    }
    
    func totalValueInUSD(gasFee: Double) -> String {
        guard let marketUsd = token.marketUsd else { return "" }
        
        let amountToSpend = totalValue(gasFee: gasFee)
        var amountInUSD = amountToSpend * marketUsd
        
        if let parent = token.parent, // ERC20Token
           let parentMarketUsd = parent.marketUsd {
            amountInUSD += gasFee * parentMarketUsd
        }
        
        let formattedUSDAmount = formatCartPrice(amountInUSD)
        return formattedUSDAmount
    }
    
    func totalValueFormatted(gasFee: Double) -> String {
        let amountToSpend = totalValue(gasFee: gasFee)
        let formattedAmount = BalanceStringFormatter.tokenFullBalanceString(balance: amountToSpend, symbol: token.symbol)
        return "(\(formattedAmount))"
    }
    
    @ViewBuilder
    func totalValueLabel() -> some View {
        if let gasFee = dataModel.gasFee {
            HStack(alignment: .top) {
                Text(String.Constants.totalEstimate.localized())
                Spacer()
                if token.isERC20Token {
                    Text("\(totalValueInUSD(gasFee: gasFee))")
                } else {
                    Text("\(totalValueInUSD(gasFee: gasFee)) \(totalValueFormatted(gasFee: gasFee))")
                }
            }
            .font(.currentFont(size: 16))
            .foregroundStyle(Color.foregroundSecondary)
            .multilineTextAlignment(.trailing)
        }
    }
    
    var confirmIcon: Image? {
        if UserDefaults.isSendingCryptoForTheFirstTime {
            return nil
        }
        if User.instance.getSettings().touchIdActivated,
           let icon = appContext.authentificationService.biometricIcon {
            return Image(uiImage: icon)
        }
        return nil
    }
}

#Preview {
    PresentAsModalPreviewView {
        NavigationStack {
            ConfirmSendTokenView(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                             token: MockEntitiesFabric.Tokens.mockUSDTToken(),
                                             amount: .tokenAmount(0.999),
                                             receiverAddress: "0x1234567890"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
    }
}
