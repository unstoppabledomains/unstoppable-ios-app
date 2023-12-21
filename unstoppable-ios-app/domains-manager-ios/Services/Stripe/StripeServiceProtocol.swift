//
//  StripeServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import Foundation

protocol StripeServiceProtocol {
    func payWithStripe() async throws
}
