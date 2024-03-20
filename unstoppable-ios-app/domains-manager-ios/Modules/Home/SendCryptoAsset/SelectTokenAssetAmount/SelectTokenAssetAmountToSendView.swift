//
//  SelectTokenAssetAmountToSendView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectTokenAssetAmountToSendView: View {
    
    let token: BalanceTokenUIDescription
    
    @State private var interpreter = NumberPadInputInterpreter()
    
    var body: some View {
        VStack {
            inputValueView()
            UDNumberPadView(inputCallback: { inputType in
                interpreter.addInput(inputType)
            })
        }
    }
}

// MARK: - Private methods
private extension SelectTokenAssetAmountToSendView {
    @ViewBuilder
    func inputValueView() -> some View {
        Text(interpreter.getInput())
            .font(.currentFont(size: 56, weight: .bold))
    }
}

#Preview {
    SelectTokenAssetAmountToSendView(token: MockEntitiesFabric.Tokens.mockUIToken())
}
