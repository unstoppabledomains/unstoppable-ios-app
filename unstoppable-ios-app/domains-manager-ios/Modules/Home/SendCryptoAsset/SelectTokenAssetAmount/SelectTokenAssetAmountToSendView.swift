//
//  SelectTokenAssetAmountToSendView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectTokenAssetAmountToSendView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel

    let data: SendCryptoAsset.SelectTokenAmountToSendData
    private var token: BalanceTokenUIDescription { data.token }

    @State private var pullUp: ViewPullUpConfigurationType?
    @State private var inputType: SendCryptoAsset.TokenAssetAmountInputType = .usdAmount
    @State private var interpreter = NumberPadInputInterpreter()
    var analyticsName: Analytics.ViewName { .sendCryptoTokenAmountInput }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.token: token.id,
                                                                         .toWallet: data.receiverAddress,
                                                                         .fromWallet: viewModel.sourceWallet.address] }
    
    var body: some View {
        VStack(spacing: isIPSE ? 8 : 57) {
            VStack(spacing: 8) {
                inputValueView()
                convertedValueView()
            }
            VStack(spacing: isIPSE ? 8 : 32) {
                VStack(spacing: 16) {
                    tokenInfoView()
                    UDNumberPadView(inputCallback: { inputType in
                        interpreter.addInput(inputType)
                    })
                }
                confirmButton()
            }
        }
        .padding(16)
        .animation(.default, value: UUID())
        .trackAppearanceAnalytics(analyticsLogger: self)
        .addNavigationTopSafeAreaOffset()
        .viewPullUp($pullUp)
    }
}

// MARK: - Input value
private extension SelectTokenAssetAmountToSendView {
    @ViewBuilder
    func inputValueView() -> some View {
        currentInputTypeValueView()
            .withoutAnimation()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
    
    @ViewBuilder
    func currentInputTypeValueView() -> some View {
        switch inputType {
        case .usdAmount:
            usdInputValue()
        case .tokenAmount:
            tokenInputValue()
        }
    }
    
    var usdInputString: String {
        formatCartPrice(interpreter.getInterpretedNumber())
    }
    
    @ViewBuilder
    func usdInputValue() -> some View {
        primaryInputAmountText(usdInputString)
    }
    
    @ViewBuilder
    func tokenInputValue() -> some View {
        HStack(spacing: 12) {
            BalanceTokenIconsView(token: token)
            primaryInputAmountText(interpreter.getInput())
        }
    }
    
    @ViewBuilder
    func primaryInputAmountText(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 56, weight: .bold))
            .foregroundStyle(Color.foregroundDefault)
    }
}

// MARK: - Converted value
private extension SelectTokenAssetAmountToSendView {
    var hasSufficientFunds: Bool {
        inputValueFor(inputType: .tokenAmount) <= token.balance
    }
    
    @ViewBuilder
    func convertedValueView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            switchInputType()
        } label: {
            if hasSufficientFunds {
                convertedValueLabel()
            } else {
                insufficientFundsLabel()
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func convertedValueLabel() -> some View {
        HStack(spacing: 8) {
            currentConvertedTypeValueView()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Image.arrowsTopBottom
                .resizable()
                .squareFrame(24)
        }
        .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func insufficientFundsLabel() -> some View {
        Text(String.Constants.notEnoughToken.localized(token.symbol))
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundDanger)
            .frame(height: 24)
    }
    
    func switchInputType() {
        switch self.inputType {
        case .usdAmount:
            self.inputType = .tokenAmount
        case .tokenAmount:
            self.inputType = .usdAmount
        }
    }
    
    @ViewBuilder
    func currentConvertedTypeValueView() -> some View {
        switch inputType {
        case .usdAmount:
            tokenConvertedValue()
        case .tokenAmount:
            usdConvertedValue()
        }
    }
    
    func inputValueFor(inputType: SendCryptoAsset.TokenAssetAmountInputType) -> Double {
        getCurrentInput().valueOf(type: inputType,
                                  for: token)
    }
    
    var usdConvertedString: String {
        formatCartPrice(inputValueFor(inputType: .usdAmount))
    }
    
    var tokenConvertedString: String {
        BalanceStringFormatter.tokenFullBalanceString(balance: inputValueFor(inputType: .tokenAmount),
                                                      symbol: token.symbol)
    }
    
    @ViewBuilder
    func usdConvertedValue() -> some View {
        convertedAmountText(usdConvertedString)
    }
    
    @ViewBuilder
    func tokenConvertedValue() -> some View {
        convertedAmountText(tokenConvertedString)
    }
    
    @ViewBuilder
    func convertedAmountText(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 16, weight: .medium))
    }
}

// MARK: - Token info
private extension SelectTokenAssetAmountToSendView {
    @ViewBuilder
    func tokenInfoView() -> some View {
        HStack {
            HStack(spacing: 16) {
                BalanceTokenIconsView(token: token)
                HStack(spacing: 0) {
                    tokenNameAndBalance()
                    Spacer()
                    usingMaxButton()
                }
            }
        }
        .padding(12)
        .background(Color.backgroundOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    func tokenNameAndBalance() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(token.name)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            Text(token.formattedBalanceWithSymbol)
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
    
    var isUsingMax: Bool { 
        switch inputType {
        case .usdAmount:
            return inputValueFor(inputType: .usdAmount) == token.balanceUsd
        case .tokenAmount:
            return inputValueFor(inputType: .tokenAmount) == token.balance
        }
    }
    
    @ViewBuilder
    func usingMaxButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .useMax)
            maxButtonPressed()
        } label: {
            Text(String.Constants.max.localized())
                .foregroundStyle(isUsingMax ? Color.foregroundAccentMuted : Color.foregroundAccent)
        }
        .disabled(isUsingMax)
        .buttonStyle(.plain)
        .padding(.init(horizontal: 16))
    }
    
    func maxButtonPressed() {
        guard !isUsingMax else { return }
        
        pullUp = .default(.maxCryptoSendInfoPullUp(token: token))
        setMaxInputValue()
    }
    
    func setMaxInputValue() {
        self.inputType = .tokenAmount
        interpreter.setInput(token.balance)
    }
}

// MARK: - Private methods
private extension SelectTokenAssetAmountToSendView {
    @ViewBuilder
    func confirmButton() -> some View {
        UDButtonView(text: String.Constants.review.localized(),
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .confirm,
                                           parameters: [.value: String(getCurrentInput().valueOf(type: .tokenAmount, for: token))])
            viewModel.handleAction(.userTokenValueSelected(.init(receiver: data.receiver,
                                                                 token: token,
                                                                 amount: getCurrentInput(), 
                                                                 receiverAddress: data.receiverAddress)))
        }
                     .disabled(interpreter.getInterpretedNumber() <= 0 || !hasSufficientFunds)
    }
    
    func getCurrentInput() -> SendCryptoAsset.TokenAssetAmountInput {
        switch inputType {
        case .usdAmount:
            .usdAmount(interpreter.getInterpretedNumber())
        case .tokenAmount:
            .tokenAmount(interpreter.getInterpretedNumber())
        }
    }
}

#Preview {
    NavigationStack {
        SelectTokenAssetAmountToSendView(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                                     token: MockEntitiesFabric.Tokens.mockUIToken(),
                                                     receiverAddress: "0x1234567890"))
    }
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
