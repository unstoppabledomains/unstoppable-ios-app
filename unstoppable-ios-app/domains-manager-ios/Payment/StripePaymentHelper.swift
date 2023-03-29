//
//  StripePaymentHelper.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 26.05.2021.
//

import Foundation
import UIKit
import Stripe
import PassKit

struct StripePaymentHelper {
    weak var hostVc: UIViewController?
    let txCost: NetworkService.TxCost
    
    init(hostVc: UIViewController, txCost: NetworkService.TxCost) {
        self.hostVc = hostVc
        self.txCost = txCost
    }
    
    @MainActor
    mutating func requestPayment(countryCode: String) {
        let merchantIdentifier = PaymentConfiguration.Merchant.identifier
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier,
                                                      country: countryCode,
                                                      currency: PaymentConfiguration.usdCurrencyLabel)
        
        let amountInUsd = NSDecimalNumber( value: PaymentConfiguration.centsIntoDollars(cents: txCost.price) )
        
        // Configure the line items on the payment request
        let udFeeLabel = String.Constants.udFeeLabel.localized()
        let ethGasFeeLabel = String.Constants.ethGasFeeLabel.localized()

        paymentRequest.paymentSummaryItems = [
            // The final line should represent your company;
            // it'll be prepended with the word "Pay" (i.e. "Pay iHats, Inc $50")
            PKPaymentSummaryItem(label: udFeeLabel, amount: 0.00),
            PKPaymentSummaryItem(label: ethGasFeeLabel, amount: amountInUsd),
            PKPaymentSummaryItem(label: String.Constants.udCompanyName.localized(), amount: amountInUsd),
        ]
        
        if let appC = STPApplePayContext(paymentRequest: paymentRequest,
                                         delegate: (hostVc as! STPApplePayContextDelegate)) {
            appC.presentApplePay()
        }
    }
    
    func isApplePaySupported() -> Bool {
        StripeAPI.deviceSupportsApplePay()
    }
    
    struct PaymentIntent {
        let secret: String
        let intent: String
    }
    
    func forwardClientSecret(txCost: NetworkService.TxCost, completion: STPIntentClientSecretCompletionBlock) {
        completion(txCost.stripeSecret, nil)
    }
    
    /*
    static func fetchClientSecret(completion: @escaping STPIntentClientSecretCompletionBlock) {
        // Retrieve the PaymentIntent client secret from your backend
        // Call the completion block with the client secret or an error
        
        Self.createPaymentIntent(country: "US") { result in
            switch result {
            case .fulfilled(let clientSecret):
                completion(clientSecret, nil)
            case .rejected(let error):
                // A real app should retry this request if it was a network error.
                completion(error.localizedDescription, error)
                break
            }
        }
    }
    
    private static func createPaymentIntent(country: String? = nil, completion: @escaping ((Result<String>) -> Void) ) {
        let url = URL(string: "https://app2-2-2-2.herokuapp.com")!.appendingPathComponent("create_payment_intent")
        var params: [String: Any] = [
            "metadata": [
                // example-mobile-backend allows passing metadata through to Stripe
                "payment_request_id": "B3E611D1-5FA1-4410-9CEC-00958A5126CB"
            ]
        ]
        //    params["products"] = products.map({ (p) -> String in
        //        return p.emoji
        //    })
        //    if let shippingMethod = shippingMethod {
        //        params["shipping"] = shippingMethod.identifier
        //    }
        params["country"] = country
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, response, error) in
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200,
                      let data = data,
                      let json =
                        ((try? JSONSerialization.jsonObject(with: data, options: [])
                            as? [String: Any]) as [String: Any]??),
                      let secret = json?["secret"] as? String
                else {
                    completion(.rejected(error ?? PaymentError.failedToFetchClientSecret))
                    return
                }
                completion(Result.fulfilled(secret))
            })
        task.resume()
    }
 */
}
