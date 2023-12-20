//
//  StripeService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.03.2023.
//

import Foundation
import Stripe
import PassKit

final class StripeService: NSObject {
    
    typealias PurchaseResult = Result<Void, PurchaseError>
    typealias PurchaseResultCallback = (PurchaseResult)->()
    
    private(set) var paymentDetails: PaymentDetails
    
    init(paymentDetails: PaymentDetails) {
        self.paymentDetails = paymentDetails
    }
    
}

// MARK: - Open methods
extension StripeService: StripeServiceProtocol {
    static func prepare() {
        let key: String
        switch User.instance.getSettings().networkType {
        case .mainnet:
            key = PaymentConfiguration.Stripe.defaultPublishableKey
        case .testnet:
            key = PaymentConfiguration.Stripe.developmentKey
        }
        StripeAPI.defaultPublishableKey = key
    }
    
    static var isApplePaySupported: Bool {
        StripeAPI.deviceSupportsApplePay()
    }
    
    func payWithStripe() async throws {
        StripeService.prepare()
        try await withCheckedThrowingContinuation { continuation in
            payWithStripeAsync() { result in
                switch result {
                case .success:
                    continuation.resume(returning: Void())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - STPApplePayContextDelegate
extension StripeService: STPApplePayContextDelegate {
    public func applePayContext(_ context: STPApplePayContext,
                                didCreatePaymentMethod paymentMethod: STPPaymentMethod,
                                paymentInformation: PKPayment,
                                completion: @escaping STPIntentClientSecretCompletionBlock) {
        completion(paymentDetails.paymentSecret, nil)
    }

    public func applePayContext(_ context: STPApplePayContext,
                                didCompleteWith status: STPPaymentStatus,
                                error: Error?) {
        switch status {
        case .success:
            // Payment succeeded
            Debugger.printInfo(topic: .Transactions, "Update Records payment is successful")
            finishWithResult(.success(Void()))
        case .error:
            // Payment failed, show the error
            finishWithResult(.failure(.paymentFailed))
        case .userCancellation:
            // User cancelled the payment
            finishWithResult(.failure(.cancelled))
        @unknown default:
            finishWithResult(.failure(.unknownStatus))
        }
    }
}

// MARK: - Private methods
private extension StripeService {
    func payWithStripeAsync(callback: @escaping PurchaseResultCallback) {
        paymentDetails.resultCallback = callback
        guard StripeAPI.deviceSupportsApplePay() else {
            finishWithResult(.failure(.applePayNotSupported))
            return
        }
        
        DispatchQueue.main.async {
            self.startStripePayment()
        }
    }
    
    func startStripePayment() {
        let countryCode = Locale.current.regionCode ?? PaymentConfiguration.usCountryCode
        let merchantIdentifier = "merchant.unstoppabledomains.pay"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier,
                                                      country: countryCode,
                                                      currency: PaymentConfiguration.usdCurrencyLabel)
        
        let amountInUsd = NSDecimalNumber( value: PaymentConfiguration.centsIntoDollars(cents: paymentDetails.amount) )
        
        paymentRequest.paymentSummaryItems = [
            // The final line should represent your company;
            // it'll be prepended with the word "Pay" (i.e. "Pay iHats, Inc $50")
            PKPaymentSummaryItem(label: String.Constants.udCompanyName.localized(), amount: amountInUsd),
        ]
        
        if let appC = STPApplePayContext(paymentRequest: paymentRequest,
                                         delegate: self) {
            appC.presentApplePay()
        } else {
            finishWithResult(.failure(.cantInitStripe))
        }
    }
    
    func finishWithResult(_ result: PurchaseResult) {
        paymentDetails.resultCallback?(result)
    }
}

// MARK: - Open methods
extension StripeService {
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
