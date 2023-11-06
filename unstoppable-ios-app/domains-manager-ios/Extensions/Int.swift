//
//  Int.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.10.2023.
//

import Foundation

extension Int {
    var asFormattedKsString: String {
        let num = abs(Double(self))
        let sign = self < 0 ? "-" : ""
        
        switch num {
        case 1_000_000_000...:
            return "\(sign)\((num / 1_000_000_000).reduceScale(to: 1))B"
        case 1_000_000...:
            return "\(sign)\((num / 1_000_000).reduceScale(to: 1))M"
        case 1_000...:
            return "\(sign)\((num / 1_000).reduceScale(to: 1))K"
        case 0...:
            return "\(self)"
        default:
            return "\(sign)\(self)"
        }
    }
}
