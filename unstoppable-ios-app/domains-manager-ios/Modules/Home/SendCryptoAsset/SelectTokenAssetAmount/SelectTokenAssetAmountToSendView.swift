//
//  SelectTokenAssetAmountToSendView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectTokenAssetAmountToSendView: View {
    
    let token: BalanceTokenUIDescription
    
    @State private var inputType: SendCryptoAsset.TokenAssetAmountInputType = .usdAmount
    @State private var interpreter = NumberPadInputInterpreter()
    
    var body: some View {
        VStack(spacing: 57) {
            VStack(spacing: 8) {
                inputValueView()
                convertedValueView()
            }
            VStack(spacing: 32) {
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
    }
}

// MARK: - Input value
private extension SelectTokenAssetAmountToSendView {
    @ViewBuilder
    func inputValueView() -> some View {
        currentInputTypeValueView()
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
        usdString(interpreter.getInput())
    }
    
    @ViewBuilder
    func usdInputValue() -> some View {
        primaryInputAmountText(usdInputString)
    }
    
    @ViewBuilder
    func tokenInputValue() -> some View {
        primaryInputAmountText(interpreter.getInput())
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
    @ViewBuilder
    func convertedValueView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            switchInputType()
        } label: {
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
        .buttonStyle(.plain)
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
    
    var usdConvertedString: String {
        usdString(interpreter.getInput())
    }
    
    func usdString(_ str: String) -> String {
        "$\(str)"
    }
    
    @ViewBuilder
    func usdConvertedValue() -> some View {
        convertedAmountText(usdInputString)
    }
    
    @ViewBuilder
    func tokenConvertedValue() -> some View {
        convertedAmountText("\(interpreter.getInput()) \(token.symbol)")
    }
    
    @ViewBuilder
    func convertedAmountText(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 16, weight: .medium))
    }
}

// MARK: - Private methods
private extension SelectTokenAssetAmountToSendView {
    @ViewBuilder
    func tokenInfoView() -> some View {
        HStack {
            HStack(spacing: 16) {
                BalanceTokenIconsView(token: token)
                tokenNameAndBalance()
                Spacer()
                usingMaxButton()
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
    
    var isUsingMax: Bool { false }
    var useMaxButtonTitle: String {
        if isUsingMax {
            String.Constants.usingMax.localized()
        } else {
            String.Constants.useMax.localized()
        }
    }
    
    @ViewBuilder
    func usingMaxButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
        } label: {
            Text(useMaxButtonTitle)
                .foregroundStyle(isUsingMax ? Color.foregroundAccentMuted : Color.foregroundAccent)
        }
        .buttonStyle(.plain)
        .padding(.init(horizontal: 16))
    }
}

// MARK: - Private methods
private extension SelectTokenAssetAmountToSendView {
    @ViewBuilder
    func confirmButton() -> some View {
        UDButtonView(text: String.Constants.review.localized(),
                     style: .large(.raisedPrimary)) {
            
        }
                     .disabled(interpreter.getInterpretedNumber() <= 0)
    }
}

#Preview {
    SelectTokenAssetAmountToSendView(token: MockEntitiesFabric.Tokens.mockUIToken())
}
