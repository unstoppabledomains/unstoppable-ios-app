//
//  SelectTokenAssetAmountToSendView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectTokenAssetAmountToSendView: View {
    
    @State private var interpreter = NumberPadInputInterpreter()

    let token: BalanceTokenUIDescription
    
    var body: some View {
        UDNumberPadView(inputCallback: { inputType in
            interpreter.addInput(inputType)
        })
    }
}

#Preview {
    SelectTokenAssetAmountToSendView(token: MockEntitiesFabric.Tokens.mockUIToken())
}
