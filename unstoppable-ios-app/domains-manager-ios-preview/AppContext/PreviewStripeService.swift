//
//  PreviewStripeService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class StripeService: NSObject {
    typealias PurchaseResult = Result<Void, PurchaseError>
    typealias PurchaseResultCallback = (PurchaseResult)->()
    private(set) var paymentDetails: PaymentDetails

    static func prepare() {
        
    }
    init(paymentDetails: PaymentDetails) {
        self.paymentDetails = paymentDetails
    }
    struct PaymentDetails {
        let amount: Int
        let paymentSecret: String
        var resultCallback: PurchaseResultCallback? = nil
    }
    enum PurchaseError: Error {
        case cancelled
        case cantInitStripe
        case paymentFailed
        case unknownStatus
        case applePayNotSupported
    }
}

extension StripeService: StripeServiceProtocol {
    func payWithStripe() async throws {
        
    }
    
    
    static var isApplePaySupported: Bool {
        true
    }
}
