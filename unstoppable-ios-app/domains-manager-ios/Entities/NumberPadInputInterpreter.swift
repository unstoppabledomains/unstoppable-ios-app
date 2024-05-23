//
//  NumberPadInputInterpreter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

struct NumberPadInputInterpreter {
    private var input: String = ""
    
    mutating func addInput(_ inputType: UDNumberButtonView.InputType) {
        switch inputType {
        case .number(let num):
            if num == 0,
               input == "0" {
                return 
            }
            input.append(String(num))
        case .dot:
            if !isContainsDot() {
                input += .dotSeparator
            }
        case .erase:
            if !input.isEmpty {
                input.removeLast()
            }
        }
    }
    
    private func isContainsDot() -> Bool {
        input.contains(.dotSeparator)
    }
    
    func getInterpretedNumber() -> Double {
        if input.last == .dotSeparator {
            return Double(input.dropLast()) ?? 0
        }
        return Double(input) ?? 0
    }
    
    func getInput() -> String {
        if input.isEmpty {
            return "0"
        } else if input.first == String.dotSeparator.first {
            return "0" + input
        }
        return input
    }
    
    mutating func setInput(_ input: Double) {
        self.input = input.formatted(toMaxNumberAfterComa: 50, minNumberAfterComa: 0) 
    }
}
