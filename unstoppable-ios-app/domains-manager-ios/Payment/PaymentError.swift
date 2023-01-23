//
//  PaymentError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.09.2022.
//

import Foundation

enum PaymentError: String, Error, RawValueLocalizable {
    case paymentNotConfirmed
    case applePayFailed
    case applePayNotSupported
    case failedToFetchClientSecret
    case paymentContextNil
    case intentNilError
    case stripePaymentHelperNil
    case cryptoPayloadNil
    case fetchingTxCostFailedInternet
    case fetchingTxCostFailedParsing
    case noPayloadCreated
    case unknown
}
