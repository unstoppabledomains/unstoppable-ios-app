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
            inputValueView()
            VStack(spacing: 16) {
                tokenInfoView()
                UDNumberPadView(inputCallback: { inputType in
                    interpreter.addInput(inputType)
                })
            }
        }
        .padding(16)
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
        "$\(interpreter.getInput())"
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

#Preview {
    SelectTokenAssetAmountToSendView(token: MockEntitiesFabric.Tokens.mockUIToken())
}
