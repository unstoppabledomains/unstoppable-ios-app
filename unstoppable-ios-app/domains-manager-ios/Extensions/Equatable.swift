//
//  Equatable.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.12.2022.
//

import Foundation

extension Equatable {
    func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}
