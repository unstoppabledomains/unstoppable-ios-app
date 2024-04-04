//
//  UDNumberButtonView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct UDNumberButtonView: View {
    
    @Environment(\.isEnabled) private var isEnabled

    let inputType: InputType
    let callback: MainActorCallback

    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback()
        } label: {
            Text("")
        }
        .buttonStyle(ControllableButtonStyle(state: .init(isEnabled: isEnabled),
                                             change: { state in
            contentForCurrentInputType()
                .squareFrame(64)
            .foregroundColor(Color.foregroundDefault)
            .background(backgroundColorFor(pressed: state.pressed))
            .clipShape(Circle())
        }))
        .squareFrame(64)
    }
}

// MARK: - Private methods
private extension UDNumberButtonView {
    @ViewBuilder
    func backgroundColorFor(pressed: Bool) -> some View {
        if pressed {
            Color.backgroundSubtle
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder
    func contentForCurrentInputType() -> some View {
        switch inputType {
        case .number(let num):
            textContent(String(num))
        case .dot:
            textContent(".")
        case .erase:
            Image.chevronRight
                .resizable()
                .squareFrame(24)
                .rotationEffect(.degrees(180))
        }
    }
    
    @ViewBuilder
    func textContent(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 28, weight: .medium))
    }
}

// MARK: - Open methods
extension UDNumberButtonView {
    enum InputType {
        case number(Int)
        case dot
        case erase
    }
}

#Preview {
    HStack {
        UDNumberButtonView(inputType: .dot) {
            
        }
        UDNumberButtonView(inputType: .number(0)) {
            
        }
        UDNumberButtonView(inputType: .erase) {
            
        }
    }
}
