//
//  Double.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.07.2022.
//

import Foundation

extension Double {
    var ethValue: Double { self / 1_000_000_000_000_000_000 }
}

extension Double {
    func reduceScale(to places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        let newDecimal = multiplier * self // move the decimal right
        let truncated = Double(Int(newDecimal)) // drop the fraction
        let originalDecimal = truncated / multiplier // move the decimal back
        return originalDecimal
    }
    
    func rounded(toDecimalPlaces decimalPlaces: Int) -> Double {
        let multiplier = pow(10.0, Double(decimalPlaces))
        return (self * multiplier).rounded() / multiplier
    }
    
    func formatted(toMaxNumberAfterComa maxNumberAfterComa: Int,
                   minNumberAfterComa: Int = 2) -> String {
        
        let str = String(self)
        let maxNativelySupportedDecimalsAfterCome = 14
        if maxNumberAfterComa > maxNativelySupportedDecimalsAfterCome,
           let indexOfDecimal = str.firstIndex(of: ".") {
            let fractionalPart = str[str.index(after: indexOfDecimal)...]
            if fractionalPart.count > maxNativelySupportedDecimalsAfterCome {
                let integerPart = str[..<indexOfDecimal]
                let roundedFractionalPart = String(fractionalPart.prefix(maxNumberAfterComa))
                
                return "\(integerPart).\(roundedFractionalPart)"
            }
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maxNumberAfterComa
        formatter.minimumFractionDigits = minNumberAfterComa
        formatter.roundingMode = .halfEven
        
        return formatter.string(from: self as NSNumber) ?? "0.0"
    }
    
    func formattedBalance() -> String {
        formatted(toMaxNumberAfterComa: 2)
    }
}
