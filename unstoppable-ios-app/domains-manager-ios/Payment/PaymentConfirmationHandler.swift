//
//  PaymentConfirmationHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

protocol PaymentConfirmationHandler {
    func payIfNeededToUpdate(domain: DomainItem?,
                             using paymentInfo: NetworkService.ActionsPaymentInfo) async throws
}

extension PaymentConfirmationHandler {
    func payIfNeededToUpdate(domain: DomainItem?,
                             using paymentInfo: NetworkService.ActionsPaymentInfo) async throws {
        guard domain?.doesRequirePayment() ?? false else { // nil domain implies no paid domain
            return
        }
        guard StripeService.isApplePaySupported else {
            throw PaymentError.applePayNotSupported
        }
        
        guard let view = await appContext.coreAppCoordinator.topVC else { return }
        
        try await appContext.pullUpViewService.showPayGasFeeConfirmationPullUp(gasFeeInCents: Int(paymentInfo.totalAmount),
                                                                               in: view)
        await view.dismissPullUpMenu()
        
        let paymentService = appContext.createStripeInstance(amount: Int(paymentInfo.totalAmount),
                                                             using: paymentInfo.clientSecret)
        try await paymentService.payWithStripe()
    }
}

extension UIViewController: PaymentConfirmationHandler { }
