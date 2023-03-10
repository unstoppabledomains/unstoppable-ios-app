//
//  PaymentConfirmationDelegate.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 14.06.2021.
//

import Foundation
import UIKit
import Stripe
import PassKit

protocol PaymentConfirmationDelegate: UIViewController {
    var storedPayload: NetworkService.TxPayload? { set get }
    var storedContinuation: CheckedContinuation<NetworkService.TxPayload, any Error>? { get set }

    var paymentInProgress: Bool { set get }
    var stripePaymentHelper: StripePaymentHelper? { set get }
}

extension PaymentConfirmationDelegate {
    func fetchPaymentConfirmationAsync(for domain: DomainItem?,
                                             payload: NetworkService.TxPayload) async throws -> NetworkService.TxPayload {
        return try await withCheckedThrowingContinuation { continuation in
            guard domain?.doesRequirePayment() ?? false else { // nil domain implies no paid domain
                continuation.resume(returning: payload)
                return
            }
            let stripePaymentHelper = StripePaymentHelper(hostVc: self, txCost: payload.getTxCost())
            guard stripePaymentHelper.isApplePaySupported() else {
                continuation.resume(throwing: PaymentError.applePayNotSupported)
                return
            }
            
            self.stripePaymentHelper = stripePaymentHelper
            
            Task {
                let feeInCents = payload.txCost?.price ?? 0
                do {
                    try await appContext.pullUpViewService.showPayGasFeeConfirmationPullUp(gasFeeInCents: feeInCents, in: self)
                    await dismissPullUpMenu()
                    
                    self.storedContinuation = continuation
                    self.storedPayload = payload
                    self.paymentInProgress = true
                    
                    let countryCode = Locale.current.regionCode ?? PaymentConfiguration.usCountryCode
                    await self.stripePaymentHelper!.requestPayment(countryCode: countryCode)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// TODO: - Refactoring
extension UIViewController: STPApplePayContextDelegate {
    public func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        guard let self = self as? PaymentConfirmationDelegate else { return }
        
        guard let helper = self.stripePaymentHelper else {
            Debugger.printFailure("StripePaymentHelper is nil", critical: true)
            completion("stripePaymentHelper is nil", PaymentError.stripePaymentHelperNil)
            return
        }
        helper.forwardClientSecret(txCost: self.storedPayload!.getTxCost(), completion: completion)
    }
    
    public func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
        guard let self = self as? PaymentConfirmationDelegate else { return }

        switch status {
        case .success:
            // Payment succeeded
            Debugger.printInfo(topic: .Transactions, "Update Records payment is successful")
            self.storedContinuation?.resume(returning: self.storedPayload!)
        case .error:
            // Payment failed, show the error
            self.storedContinuation?.resume(throwing: error ?? PaymentError.unknown)
        case .userCancellation:
            // User cancelled the payment
            self.storedContinuation?.resume(throwing: error ?? PaymentError.paymentNotConfirmed)
        @unknown default:
            self.storedContinuation?.resume(throwing: error ?? PaymentError.unknown)
        }
        self.stripePaymentHelper = nil
        self.storedContinuation = nil
    }
}
