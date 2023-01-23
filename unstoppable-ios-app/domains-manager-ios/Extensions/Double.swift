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
