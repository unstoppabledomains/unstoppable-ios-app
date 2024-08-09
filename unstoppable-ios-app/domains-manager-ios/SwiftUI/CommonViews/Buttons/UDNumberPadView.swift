//
//  UDNumberPadView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct UDNumberPadView: View {
    
    let hSpacing: CGFloat = 48
    
    let inputCallback: (UDNumberButtonView.InputType)->()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: hSpacing) {
                numberButtonFor(inputType: .number(1))
                numberButtonFor(inputType: .number(2))
                numberButtonFor(inputType: .number(3))
            }
            HStack(spacing: hSpacing) {
                numberButtonFor(inputType: .number(4))
                numberButtonFor(inputType: .number(5))
                numberButtonFor(inputType: .number(6))
            }
            HStack(spacing: hSpacing) {
                numberButtonFor(inputType: .number(7))
                numberButtonFor(inputType: .number(8))
                numberButtonFor(inputType: .number(9))
            }
            HStack(spacing: hSpacing) {
                numberButtonFor(inputType: .dot)
                numberButtonFor(inputType: .number(0))
                numberButtonFor(inputType: .erase)
            }
        }
    }
}

// MARK: - Private methods
private extension UDNumberPadView {
    @ViewBuilder
    func numberButtonFor(inputType: UDNumberButtonView.InputType) -> some View {
        UDNumberButtonView(inputType: inputType) {
            didPressInputType(inputType)
        }
    }
    
    func didPressInputType(_ inputType: UDNumberButtonView.InputType) {
        inputCallback(inputType)
    }
}

#Preview {
    var interpreter = NumberPadInputInterpreter()
    
    return UDNumberPadView(inputCallback: { inputType in
        interpreter.addInput(inputType)
    })
}

