//
//  SwiftUIViewPaymentHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.01.2024.
//

import Foundation
import SwiftUI

final class SwiftUIViewPaymentHandler: ObservableObject, PaymentConfirmationDelegate {
    var stripePaymentHelper: StripePaymentHelper?
    var storedPayload: NetworkService.TxPayload?
    var storedContinuation: CheckedContinuation<NetworkService.TxPayload, Error>?
    var paymentInProgress: Bool = false
    
    /// For MATIC Free transactions only
    func fetchPaymentConfirmationAsync(for domain: DomainItem?,
                                       payload: NetworkService.TxPayload) async throws -> NetworkService.TxPayload {
        return try await withCheckedThrowingContinuation { continuation in
            guard domain?.doesRequirePayment() ?? false else { // nil domain implies no paid domain
                continuation.resume(returning: payload)
                return
            }
            continuation.resume(throwing: PaymentError.applePayNotSupported)
        }
    }
    
}
