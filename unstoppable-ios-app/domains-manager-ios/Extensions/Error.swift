//
//  Error.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2023.
//

import Foundation

extension Error {
    
    var titleAndMessage: (title: String, message: String) {
        var message: String
        let title: String
        
        if self is TransactionError {
            title = String.Constants.transactionFailed.localized()
            message = String.Constants.pleaseTryAgain.localized()
        } else if let networkError = self as? NetworkLayerError,
                  case .notConnectedToInternet = networkError {
            title = String.Constants.connectionLost.localized()
            message = String.Constants.pleaseCheckInternetConnection.localized()
        } else if let jrpcError = self as? NetworkService.JRPCError {
            switch jrpcError {
            case .failedFetchInfuraGasPrices:
                title = String.Constants.gasFeeFailed.localized()
                message = String.Constants.pleaseTryAgain.localized()
            case .failedFetchNonce:
                title = String.Constants.nonceFailed.localized()
                message = String.Constants.pleaseTryAgain.localized()
            default: title = String.Constants.somethingWentWrong.localized()
                    message = String.Constants.pleaseTryAgain.localized()
            }
        } else {
            title = String.Constants.somethingWentWrong.localized()
            message = String.Constants.pleaseTryAgain.localized()
        }
        
#if DEBUG
        message = self.localizedDescription
#endif
        
        return (title, message)
    }
}
