//
//  MockStripeService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 10.11.2023.
//

import Foundation

final class MockStripeService {
    
    let amount: Int
    
    init(amount: Int) {
        self.amount = amount
    }
}

// MARK: - StripeServiceProtocol
extension MockStripeService: StripeServiceProtocol {
    func payWithStripe() async throws {
        await Task.sleep(seconds: 1)
    }
}
