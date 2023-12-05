//
//  TransactionError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

enum TransactionError: String, LocalizedError {
    case TransactionNotPending
    case SuggestedGasPriceNotHigher
    case FailedToFindDomainById
    case FailedToMerge
    case EmptyNonce
    case InvalidValue
    
    public var errorDescription: String? {
        return rawValue
    }
}
